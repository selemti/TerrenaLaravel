# Análisis Exhaustivo de Base de Datos - Esquema selemti
**Proyecto**: TerrenaLaravel - ERP para Restaurantes
**Fecha**: 30 de octubre de 2025
**Analista**: Claude Code (IA Specialist)
**Objetivo**: Elevar la BD a nivel de ERP enterprise de alto nivel

---

## Resumen Ejecutivo

El esquema `selemti` contiene **118 tablas** con un total de **~4.5 MB** de datos. El análisis revela:

- ⚠️ **23 problemas críticos** que impactan operaciones
- 🔴 **Duplicación de sistemas** (legacy vs nuevo)
- 🟡 **45% de tablas sin integridad referencial completa**
- 🟢 **Oportunidades de optimización** para escalabilidad

**Nivel actual**: **Funcional pero fragmentado**
**Nivel objetivo**: **ERP Enterprise Grade**

---

## 1. Arquitectura Actual - Problemas Identificados

### 1.1 ⚠️ **CRÍTICO: Sistemas Paralelos No Consolidados**

Se detectaron **DOS sistemas completos ejecutándose en paralelo**:

| Componente | Sistema Legacy | Sistema Nuevo | Estado |
|------------|---------------|---------------|--------|
| **Usuarios** | `usuario` + `rol` | `users` + `roles` | ❌ Duplicado |
| **Sucursales** | `sucursal` | `cat_sucursales` | ❌ Duplicado |
| **Almacenes** | `bodega` | `cat_almacenes` | ❌ Duplicado |
| **Items** | `insumo` + `lote` | `items` + `inventory_batch` | ❌ Duplicado |
| **Recetas** | `receta` | `receta_cab` | ❌ Duplicado |
| **Unidades** | `unidad_medida_legacy` | `unidades_medida_legacy` | ❌ Duplicado |

**Impacto**:
- Inconsistencia de datos entre sistemas
- Código con lógica duplicada
- Complejidad innecesaria en desarrollo
- Riesgo de usar tabla incorrecta

**Recomendación**: **Consolidación urgente en sistema único**

---

### 1.2 🔴 **Duplicación de Tablas de Unidades de Medida**

Existen **6 tablas** para gestionar unidades:

```
1. cat_unidades (29 registros, 72 KB)
2. unidad_medida_legacy (3 registros, 48 KB)
3. unidades_medida_legacy (22 registros, 40 KB) ← CANÓNICA
4. conversiones_unidad_legacy
5. cat_uom_conversion
6. uom_conversion_legacy
```

**Problemas**:
- Código usa diferentes tablas indistintamente
- FKs apuntan a tablas diferentes
- Conversiones duplicadas en 3 lugares

**Solución propuesta**:
- Consolidar en `unidades_medida_legacy` (ya en proceso)
- Eliminar tablas redundantes
- Migrar todas las FKs

---

### 1.3 🟡 **Integridad Referencial Incompleta**

De **118 tablas**, solo **~55%** tienen FKs completas.

#### Tablas Críticas Sin FKs Necesarias:

| Tabla | FK Faltante | Impacto |
|-------|-------------|---------|
| `recipe_cost_history` | → `receta_cab.id` | Alto - Costos huérfanos |
| `inventory_counts` | → `cat_almacenes.id` | Alto - Conteos sin almacén |
| `inventory_count_lines` | → `items.id` | Alto - Líneas sin item |
| `production_orders` | → `items.id` | Medio - Órdenes sin output |
| `purchase_suggestions` | → `items.id` | Medio - Sugerencias sin item |
| `pos_map` | ✅ CORREGIDO | - |

**Impacto Total**:
- ~15-20 tablas transaccionales sin FKs completas
- Posibilidad de datos huérfanos
- Imposibilidad de CASCADE deletes seguros

---

### 1.4 🔴 **Incompatibilidades de Tipos de Datos**

Detectadas **7 incompatibilidades** críticas:

```sql
-- PROBLEMA 1: Items con tipos inconsistentes
items.id                         : VARCHAR(20)
inventory_count_lines.item_id    : BIGINT      ❌ INCOMPATIBLE
cost_layer.item_id               : VARCHAR(20) ✓ Compatible
mov_inv.item_id                  : VARCHAR(20) ✓ Compatible

-- PROBLEMA 2: Recetas con tipos inconsistentes
receta_cab.id                    : VARCHAR(20)
recipe_cost_history.recipe_id    : BIGINT      ❌ INCOMPATIBLE

-- PROBLEMA 3: Almacenes
cat_almacenes.id                 : BIGINT
inventory_counts.almacen_id      : VARCHAR     ❌ INCOMPATIBLE

-- PROBLEMA 4: inventory_snapshot (YA CORREGIDO)
inventory_snapshot.item_id       : VARCHAR(20) ✅ CORREGIDO (era UUID)
```

**Impacto**:
- Imposibilidad de crear FKs
- Queries JOIN fallan con error de tipo
- Conversiones explícitas en todas las consultas

**Solución**: Migración de tipos en Phase 3

---

### 1.5 🟠 **Primary Keys Complejas Excesivas**

Varias tablas tienen PKs compuestas de **4+ columnas**:

```sql
-- PK de 4 columnas (INNECESARIO)
pos_map (plu, sys_from, pos_system, valid_from)

-- PK de 3 columnas (EXCESIVO)
inventory_snapshot (snapshot_date, branch_id, item_id)
item_vendor (item_id, vendor_id, presentacion)

-- PK de 3 columnas con temporalidad (CONFUSO)
sesion_cajon (terminal_id, cajero_usuario_id, apertura_ts)
```

**Problemas**:
- Complejidad en FKs hijas
- Performance en JOINs
- Dificultad para mantener
- URLs complicadas (REST API)

**Recomendación**: Usar PK simple (BIGINT auto-increment) + UNIQUE constraint

---

### 1.6 🔴 **Tablas Sin Auditoría**

Solo **~30% de tablas transaccionales** tienen auditoría completa:

| Tabla | created_at | updated_at | created_by | updated_by | deleted_at |
|-------|------------|------------|------------|------------|------------|
| `items` | ❌ | ❌ | ❌ | ❌ | ❌ |
| `receta_cab` | ❌ | ❌ | ❌ | ❌ | ❌ |
| `mov_inv` | ✅ (ts) | ❌ | ❌ | ❌ | ❌ |
| `purchase_orders` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `cash_funds` | ✅ | ✅ | ✅ | ❌ | ❌ |

**Tablas críticas sin auditoría**:
- `items` (maestro de inventario)
- `receta_cab` (recetas)
- `cat_proveedores` (proveedores)
- `cat_almacenes` (almacenes)

**Impacto**:
- Imposible auditar cambios
- No hay trazabilidad
- Problemas de compliance

---

### 1.7 🟡 **Índices Faltantes para Performance**

Análisis de queries comunes revela **~25 índices faltantes**:

```sql
-- FALTANTES CRÍTICOS
CREATE INDEX idx_mov_inv_ts ON mov_inv(ts);  -- Queries por fecha
CREATE INDEX idx_mov_inv_tipo_ref ON mov_inv(tipo_ref, ref_id); -- Búsqueda por referencia
CREATE INDEX idx_items_activo ON items(activo); -- Filtro común
CREATE INDEX idx_items_category ON items(category_id); -- Filtro común
CREATE INDEX idx_receta_det_item ON receta_det(item_id); -- JOINs frecuentes
CREATE INDEX idx_purchase_orders_fecha ON purchase_orders(fecha_orden); -- Reportes
CREATE INDEX idx_ticket_det_consumo_fecha ON ticket_det_consumo(fecha_consumo); -- Análisis ventas
```

**Impacto**:
- Queries lentas en reportes
- Full table scans en tablas grandes
- Cuellos de botella en concurrencia

---

### 1.8 🟠 **Campos Redundantes**

Se detectaron **12 campos redundantes** que pueden calcularse:

| Tabla | Campo Redundante | Se Calcula Desde |
|-------|------------------|------------------|
| `items` | `unidad_medida` (VARCHAR) | → `unidad_medida_id` FK |
| `receta_det` | `unidad_medida` (VARCHAR) | → item.unidad_medida_id |
| `precorte` | `total_sistema` | → SUM(precorte_efectivo + precorte_otros) |
| `postcorte` | `diferencia` | → total_declarado - total_sistema |
| `ticket_det_consumo` | `costo_total` | → qty_consumida * costo_unitario |

**Impacto**:
- Riesgo de inconsistencia
- Espacio desperdiciado
- Lógica duplicada en código

**Recomendación**: Eliminar y usar vistas computadas

---

## 2. Arquitectura Objetivo - ERP Enterprise Grade

### 2.1 Principios de Diseño

**1. Single Source of Truth (SSOT)**
- Un solo sistema de usuarios, sucursales, almacenes, items
- Consolidar sistemas legacy y nuevo

**2. Integridad Referencial Completa**
- Todas las tablas transaccionales con FKs
- CASCADE deletes donde aplique
- RESTRICT deletes en maestros

**3. Auditoría Universal**
- Todas las tablas con: `created_at`, `updated_at`, `created_by_user_id`, `deleted_at`
- Soft deletes por defecto
- Tabla `audit_log` centralizada

**4. Performance por Diseño**
- Índices estratégicos en columnas consultadas
- Particionamiento en tablas históricas (>1M rows)
- Desnormalización controlada donde justificado

**5. Escalabilidad**
- Preparado para multi-tenant
- Separación de transaccional vs reporting
- Event sourcing en operaciones críticas

---

### 2.2 Módulos Propuestos (Clean Architecture)

```
selemti/
├── core/                    # Núcleo del sistema
│   ├── users                # users, roles, permissions
│   ├── branches             # cat_sucursales (canónico)
│   ├── warehouses           # cat_almacenes (canónico)
│   └── audit                # audit_log centralizado
│
├── inventory/               # Gestión de inventario
│   ├── items                # items (canónico)
│   ├── batches              # inventory_batch
│   ├── movements            # mov_inv
│   ├── counts               # inventory_counts + lines
│   ├── snapshots            # inventory_snapshot
│   └── policies             # stock_policy
│
├── purchasing/              # Compras
│   ├── vendors              # cat_proveedores
│   ├── requests             # purchase_requests + lines
│   ├── quotes               # purchase_vendor_quotes + lines
│   ├── orders               # purchase_orders + lines
│   └── suggestions          # purchase_suggestions + lines
│
├── recipes/                 # Recetas y producción
│   ├── recipes              # receta_cab (canónico)
│   ├── versions             # receta_version
│   ├── items                # receta_det
│   ├── cost_history         # recipe_cost_history
│   └── productions          # production_orders
│
├── pos/                     # Punto de venta
│   ├── sessions             # sesion_cajon
│   ├── precorte             # precorte + efectivo + otros
│   ├── postcorte            # postcorte + conciliacion
│   ├── map                  # pos_map
│   └── consumption          # ticket_det_consumo
│
├── cash/                    # Caja chica
│   ├── funds                # cash_funds
│   ├── movements            # cash_fund_movements
│   └── arqueos              # cash_fund_arqueos
│
└── catalog/                 # Catálogos
    ├── uom                  # unidades_medida_legacy (canónico)
    ├── uom_conversion       # conversiones_unidad_legacy
    ├── categories           # item_categories
    ├── payment_methods      # formas_pago
    └── labor_roles          # labor_roles
```

---

### 2.3 Convenciones de Nomenclatura Estándar

**Tablas**:
- Plural en inglés: `items`, `orders`, `movements`
- Prefijo de módulo si necesario: `pos_sessions`, `cash_funds`

**Columnas**:
- Snake_case: `created_at`, `user_id`
- Sufijo `_id` para FKs: `item_id`, `warehouse_id`
- Sufijo `_at` para timestamps: `created_at`, `approved_at`
- Sufijo `_by_user_id` para auditoría: `created_by_user_id`

**Primary Keys**:
- Siempre `id BIGSERIAL PRIMARY KEY`
- UUIDs solo para entidades distribuidas

**Foreign Keys**:
- Nomenclatura: `fk_{tabla_origen}_{columna}`
- Ejemplo: `fk_items_category`, `fk_orders_vendor`

---

## 3. Plan de Migración por Fases

### **FASE 1: Fundamentos** (Completada ✅)

**Objetivos**:
- Consolidar tablas de unidades ✅
- Corregir tipo de `inventory_snapshot.item_id` ✅
- Añadir FKs críticas iniciales ✅

**Resultado**: Base estable para desarrollo

---

### **FASE 2: Consolidación de Sistemas** (3-4 semanas)

**Objetivo**: Eliminar duplicación de sistemas legacy vs nuevo

#### 2.1 Consolidar Usuarios (Semana 1)
```sql
-- Migrar usuario → users
-- Migrar rol → roles
-- Actualizar todas las FKs
-- Eliminar tablas legacy
```

#### 2.2 Consolidar Sucursales/Almacenes (Semana 1-2)
```sql
-- Migrar sucursal → cat_sucursales
-- Migrar bodega → cat_almacenes
-- Actualizar todas las FKs
-- Eliminar tablas legacy
```

#### 2.3 Consolidar Items (Semana 2-3)
```sql
-- Unificar insumo → items
-- Migrar lote → inventory_batch
-- Actualizar todas las referencias
-- Crear vistas de compatibilidad
```

#### 2.4 Consolidar Recetas (Semana 3-4)
```sql
-- Unificar receta → receta_cab
-- Consolidar receta_insumo → receta_det
-- Actualizar sistema de versiones
```

**Entregables**:
- Sistema único consolidado
- Documentación de mapeos
- Tests de integridad

---

### **FASE 3: Integridad y Auditoría** (2-3 semanas)

**Objetivo**: FKs completas + auditoría universal

#### 3.1 Corregir Tipos Incompatibles (Semana 1)
```sql
-- Cambiar inventory_count_lines.item_id → VARCHAR(20)
-- Cambiar recipe_cost_history.recipe_id → VARCHAR(20)
-- Cambiar inventory_counts.almacen_id → BIGINT
```

#### 3.2 Añadir FKs Faltantes (Semana 1-2)
```sql
-- ~15 FKs pendientes en tablas críticas
-- Limpiar datos huérfanos antes
-- Crear FKs con CASCADE/RESTRICT apropiado
```

#### 3.3 Añadir Campos de Auditoría (Semana 2-3)
```sql
-- Añadir created_at, updated_at, created_by_user_id
-- Implementar soft deletes (deleted_at)
-- Crear triggers para updated_at automático
```

**Entregables**:
- 100% de FKs en tablas transaccionales
- Auditoría completa
- Scripts de verificación

---

### **FASE 4: Optimización de Performance** (2 semanas)

**Objetivo**: Índices estratégicos + particionamiento

#### 4.1 Añadir Índices Estratégicos (Semana 1)
```sql
-- 25 índices identificados
-- Priorizar por impacto en queries
-- Medir mejora de performance
```

#### 4.2 Particionamiento de Tablas Históricas (Semana 2)
```sql
-- mov_inv por fecha (mensual)
-- audit_log por fecha (mensual)
-- recipe_cost_history por año
```

#### 4.3 Optimizar Primary Keys (Semana 2)
```sql
-- Simplificar PKs compuestas
-- Migrar a BIGSERIAL + UNIQUE
```

**Entregables**:
- Performance 5x en reportes
- Queries <100ms
- Plan de mantenimiento de índices

---

### **FASE 5: Funcionalidades Enterprise** (3-4 semanas)

**Objetivo**: Características de ERP enterprise

#### 5.1 Multi-Tenant (Semana 1)
```sql
-- Añadir tenant_id a tablas core
-- Row-Level Security (RLS)
-- Vistas por tenant
```

#### 5.2 Event Sourcing (Semana 2)
```sql
-- Tabla event_store
-- Events para operaciones críticas
-- Replay capability
```

#### 5.3 Data Warehouse (Semana 3-4)
```sql
-- Esquema selemti_dw separado
-- ETL diario de transaccional → dw
-- Fact tables + Dimension tables
```

**Entregables**:
- Sistema multi-tenant ready
- Event log completo
- Reporting warehouse

---

## 4. Métricas de Éxito

### Antes de Mejoras (Actual)
| Métrica | Valor Actual | Objetivo |
|---------|--------------|----------|
| Tablas con FKs completas | ~55% | 100% |
| Tablas con auditoría | ~30% | 100% |
| Índices estratégicos | ~40 | ~65 |
| Sistemas duplicados | 2 sistemas | 1 sistema |
| Queries >1s | ~15% | <1% |
| Datos huérfanos | ~5% | 0% |

### Después de Mejoras (Objetivo)
| Métrica | Valor Objetivo |
|---------|----------------|
| Integridad referencial | 100% |
| Auditoría completa | 100% |
| Performance queries | 95% <100ms |
| Escalabilidad | Multi-tenant ready |
| Disponibilidad | 99.9% |
| Data consistency | 100% |

---

## 5. Riesgos y Mitigaciones

### Riesgo Alto
**R1**: Downtime durante migraciones
- **Mitigación**: Migraciones en ventanas de mantenimiento, rollback plan

**R2**: Pérdida de datos en consolidación
- **Mitigación**: Backups antes de cada fase, dry-run en staging

### Riesgo Medio
**R3**: Incompatibilidad con código legacy
- **Mitigación**: Vistas de compatibilidad, feature flags

**R4**: Performance degradation inicial
- **Mitigación**: Testing de carga, monitoreo proactivo

---

## 6. Siguientes Pasos Inmediatos

### Semana 1-2 (Preparación)
1. ✅ Crear estructura de documentación
2. ✅ Mover docs de Phase 1
3. ⏭️ Generar scripts SQL para Phase 2
4. ⏭️ Crear plan de testing
5. ⏭️ Setup staging environment

### Semana 3-4 (Inicio Phase 2)
6. ⏭️ Migrar usuarios (usuario → users)
7. ⏭️ Migrar sucursales/almacenes
8. ⏭️ Tests de integridad
9. ⏭️ Documentar cambios

---

## 7. Recursos Necesarios

**Humanos**:
- 1 Backend Senior (lead)
- 1 DBA PostgreSQL
- 1 QA Engineer
- 1 DevOps (staging/prod)

**Tiempo estimado total**: **10-14 semanas** (full implementation)

**Costos estimados**:
- Infraestructura staging: $200/mes
- Herramientas (monitoring, backup): $150/mes
- Capacitación equipo: 2 semanas

---

## 8. Conclusión

El esquema `selemti` tiene una base funcional pero requiere **consolidación urgente** para alcanzar nivel enterprise.

**Prioridades inmediatas**:
1. 🔴 **Consolidar sistemas duplicados** (usuario/users, sucursal/cat_sucursales)
2. 🟠 **Completar integridad referencial** (añadir FKs faltantes)
3. 🟡 **Auditoría universal** (tracking completo de cambios)
4. 🟢 **Optimización** (índices + particionamiento)

Con las mejoras propuestas, el sistema estará **listo para escalar** y soportar operaciones de **múltiples restaurantes** con **miles de transacciones diarias**.

---

**Generado por**: Claude Code AI
**Basado en**: Análisis de 118 tablas, 439 constraints, 50+ índices
**Próximo paso**: Generar scripts SQL para Phase 2
