# MATRIZ DOCUMENTAL ACTUALIZADA V4.0 - ORQUESTADOR CLAUDE
**Fecha**: 14 Noviembre 2025
**Versión**: 1.0
**Basado en**: Auditoría FASE1-FASE6 + Análisis multi-agente + Plan Actualización V4.0

---

## 1. RESUMEN EJECUTIVO

### 1.1 Estado General

| Métrica | Valor Actual | Objetivo | Gap |
|---------|--------------|----------|-----|
| **Documentos V4.0** | 20 | 44 | +24 (120%) |
| **Carpetas módulos** | 11 | 15 | +4 (36%) |
| **Cobertura módulos** | 11/15 (73%) | 15/15 (100%) | +4 módulos |
| **Score documental** | 76% | 94% | +18 puntos |
| **Docs críticos (P0)** | 11 | 20 | +9 |
| **Docs altos (P1)** | 6 | 15 | +9 |
| **Docs medios (P2)** | 3 | 9 | +6 |

### 1.2 Leyenda de Estados

| Estado | Icono | Descripción |
|--------|-------|-------------|
| **Existe** | ✅ | Documento creado y publicado |
| **Actualizar** | 🔄 | Documento existe pero requiere actualización |
| **Ampliar** | 📝 | Documento existe pero incompleto |
| **Crear** | ⭐ | Documento NO existe, debe crearse |
| **Migrar** | 🔀 | Contenido existe en legacy, debe migrarse |
| **Consolidar** | 🔗 | Múltiples versiones, requiere fusión |

### 1.3 Leyenda de Prioridades

| Prioridad | Icono | Criterio | Esfuerzo |
|-----------|-------|----------|----------|
| **P0 - Crítica** | 🔴 | Funcionalidad core, requerida para desarrollo | 3-4h por doc |
| **P1 - Alta** | 🟡 | Funcionalidad importante, requerida mediano plazo | 2-3h por doc |
| **P2 - Media** | 🟢 | Funcionalidad complementaria, puede posponerse | 1-2h por doc |

---

## 2. MATRIZ COMPLETA (44 DOCUMENTOS)

### 2.1 ORQUESTADOR (5 documentos)

#### 2.1.1 README.md (Índice V4.0)

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/README.md` |
| **Estado** | 🔄 ACTUALIZAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 80% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 1 hora |
| **Responsable** | CLAUDE (Orquestador) |

**Contenido actual**:
- Propósito y lineamientos transversales ✅
- Documentos publicados (19 archivos) 🔄
- Ruta sugerida de trabajo ✅
- Plan depuración legacy ✅
- Recomendaciones por módulo ✅

**Gaps identificados**:
- Falta índice de 44 documentos objetivo
- No menciona documentos de orquestadores (CLAUDE, QWEN, CODEX, COPILOT)
- No incluye nueva estructura BaseDatos/, Catalogos/, Seguridad/

**Contenido a agregar**:
- § 1.5 Referencias a orquestadores (00.history/orquestadores/)
- § 2 Árbol completo 44 documentos con estados
- § 3 Índice por prioridad (P0/P1/P2)
- § 4 Changelog de actualizaciones

**Fuentes**:
- PLAN_ACTUALIZACION_V4.0.md § 11
- Análisis FASE2

---

#### 2.1.2 00_CONTRATO_SISTEMA_TERRENA_v3.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/00_Orquestador/00_CONTRATO_SISTEMA_TERRENA_v3.md` |
| **Estado** | 🔄 ACTUALIZAR |
| **Prioridad** | 🔴 P0 |
| **Score actual** | 90% |
| **Score objetivo** | 98% |
| **Esfuerzo** | 3 horas |
| **Responsable** | CLAUDE (Orquestador) |

**Contenido actual**:
- Objetivo general ✅
- Alcance completo (15 módulos) ✅
- Fuente de verdad ✅
- Arquitectura técnica ✅
- Principios rectores ✅
- Gaps críticos ✅
- Roles y responsabilidades ✅
- Reglas de gobernanza ✅
- Criterios de éxito ✅

**Gaps identificados**:
- No integra hallazgos FASE1-FASE6 completos
- No menciona "Historia del Proyecto" (insight QWEN)
- No consolida definición única "¿Qué es Terrena?" (4 versiones agentes)
- No incluye "Usuarios Clave" (7 roles confirmados)
- Métricas desactualizadas (no refleja nuevos gaps FASE6)

**Contenido a agregar**:
- § 1.3 Historia del Proyecto (QWEN insight)
- § 1.4 Definición consolidada "¿Qué es Terrena?" y "¿Qué NO es?"
- § 2.2 Usuarios Clave del Sistema (7 roles + permisos)
- § 6 Gaps críticos actualizados con FASE6 (UX score 6.5/10)
- § 11 Métricas actualizadas (189 huérfanos, 12 funciones sin doc)
- § 12 Referencias a auditorías FASE1-FASE6

**Fuentes**:
- 00.history/orquestadores/CLAUDE/00_CONTRATO_SISTEMA_CLAUDE_v2.md
- 00.history/orquestadores/QWEN/00_CONTRATO_SISTEMA_QWEN_v2.md § Historia
- 00.history/orquestadores/CODEX/00_CONTRATO_SISTEMA_CODEX_v2.md § Principios
- 00.history/orquestadores/COPILOT/00_CONTRATO_SISTEMA_COPILOT_v2.md § Definiciones
- FASE1-FASE6 completas

---

#### 2.1.3 MATRIZ_ALINEACION_V4.0.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/00_Orquestador/MATRIZ_ALINEACION_V4.0.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🔴 P0 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |
| **Responsable** | CLAUDE (Orquestador) |

**Contenido a incluir**:
- § 1 Introducción y propósito de la matriz
- § 2 Metodología de evaluación (4 dimensiones: Docs, Código, BD, UI)
- § 3-17 Matriz detallada 15 módulos (una sección por módulo)
  - Tabla: Aspecto | Estado | Evidencia | Gap
  - Dimensiones: Documentación, Código, Base de Datos, UI/UX
  - Ejemplo: Caja Chica 100%, Producción 60%
- § 18 Top 10 gaps priorizados (tabla comparativa)
- § 19 Resumen roadmap (289h / 8 sprints)
- § 20 Referencias cruzadas a otros documentos

**Fuentes a fusionar**:
1. 00.history/orquestadores/CLAUDE/01_MATRIZ_ALINEACION_CLAUDE_v2.md (base)
2. 00.history/orquestadores/QWEN/01_MATRIZ_ALINEACION_QWEN_v2.md (perspectiva modular)
3. 00.history/orquestadores/CODEX/01_MATRIZ_ALINEACION_CODEX_v2.md (precisión gaps)
4. 00.history/orquestadores/COPILOT/01_MATRIZ_ALINEACION_COPILOT_v2.md (funcionalidades confirmadas)

**Patrón de fusión**:
- Tabla comparativa 4 agentes por cada módulo
- Columnas: CLAUDE | QWEN | CODEX | COPILOT | CONSOLIDADO
- Reconocer autoría de cada insight con [Agente: insight]

**Ejemplo formato**:

```markdown
### 3.1 Módulo: Caja Chica

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 100% ✅ | 13 docs (CLAUDE, COPILOT) | Ninguno |
| **Código** | 100% ✅ | CashFund, 6 Livewire (COPILOT) | Ninguno |
| **Base de Datos** | 100% ✅ | cash_funds, triggers (CODEX) | Ninguno |
| **UI/UX** | 90% 🔄 | 12 vistas (QWEN), falta loading | Loading states |

**Insights por agente**:
- [CLAUDE]: Módulo excelente, patrón a seguir
- [QWEN]: Conexión perfecta con Finanzas
- [CODEX]: Máquina estados bien documentada
- [COPILOT]: 90 registros en BD, operativo
```

---

#### 2.1.4 BACKLOG_SPRINTS_V4.0.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/00_Orquestador/BACKLOG_SPRINTS_V4.0.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🔴 P0 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |
| **Responsable** | CLAUDE (Orquestador) |

**Contenido a incluir**:
- § 1 Introducción y metodología
- § 2 Resumen general (289h / 8 sprints / 4 meses)
- § 3-10 Sprints detallados (1 sección por sprint)
  - Sprint 1: UI/UX Crítico (24h)
  - Sprint 2: BD Crítica (48h)
  - Sprint 3-4: Documentación (48h)
  - Sprint 5-6: Código Huérfano (80h)
  - Sprint 7: Refactor (24h)
  - Sprint 8: Tests (65h)
- § 11 User stories detalladas (formato estándar)
- § 12 Criterios de aceptación por sprint
- § 13 Dependencias entre sprints
- § 14 Riesgos y mitigaciones

**Fuentes a fusionar**:
1. 00.history/orquestadores/CLAUDE/02_BACKLOG_SPRINTS_CLAUDE_v2.md (base 8 sprints)
2. 00.history/orquestadores/QWEN/02_BACKLOG_SPRINTS_QWEN_v2.md (user stories detalladas)
3. 00.history/orquestadores/CODEX/02_BACKLOG_SPRINTS_CODEX_v2.md (prioridades P0/P1/P2)
4. 00.history/orquestadores/COPILOT/02_BACKLOG_SPRINTS_COPILOT_v2.md (gaps BD específicos)

**Formato user story**:

```markdown
#### US-1.1: Forms Loading States

**Prioridad**: 🔴 P0
**Esfuerzo**: 4 horas
**Sprint**: 1
**Módulos**: Frontend (todos)

**Como** usuario del sistema
**Quiero** ver indicadores visuales cuando envío formularios
**Para** saber que mi acción está procesándose y evitar clicks duplicados

**Criterios de aceptación**:
- [ ] 40 formularios identificados (FASE6)
- [ ] Patrón wire:loading implementado en todos
- [ ] Botón deshabilitado durante submit
- [ ] Spinner + texto "Guardando..." visible
- [ ] Tests: verificar comportamiento en 5 forms críticos

**Archivos afectados**:
- resources/views/livewire/inventory/reception-create.blade.php
- resources/views/livewire/purchasing/request-create.blade.php
- [... 38 más]

**Referencias**:
- [CLAUDE FASE6]: Gap 1 - Forms sin loading states
- [CODEX]: Brecha UX crítica (riesgo doble submit)
```

---

#### 2.1.5 COMPENDIO_TECNICO.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/00_Orquestador/COMPENDIO_TECNICO.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🔴 P0 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 1 hora |
| **Responsable** | CLAUDE (Orquestador) |

**Contenido a incluir**:
- § 1 Propósito del compendio (síntesis técnica)
- § 2 Arquitectura consolidada (stack, estructura, convenciones)
- § 3 Módulos y conexiones (diagrama de dependencias)
- § 4 Base de datos resumida (tablas críticas top 20)
- § 5 Servicios clave (top 10 con firma)
- § 6 Flujos de negocio críticos (3-4 diagramas)
- § 7 Gaps prioritarios (resumen ejecutivo)
- § 8 Roadmap visual (timeline 8 sprints)
- § 9 Referencias a compendios completos (links a 00.history/)
- § 10 Glosario de términos

**Fuentes a sintetizar**:
1. 00.history/orquestadores/CLAUDE/03_COMPENDIO_SUPREMO_CLAUDE.md (50 páginas → 8)
2. 00.history/orquestadores/QWEN/03_COMPENDIO_SUPREMO_QWEN.md (historia y lecciones)
3. 00.history/orquestadores/CODEX/03_COMPENDIO_SUPREMO_FUSION_CODEX.md (radiografía global)
4. 00.history/orquestadores/COPILOT/03_COMPENDIO_SUPREMO_COPILOT.md (funcionalidades confirmadas)

**Objetivo**:
Documento de 8-10 páginas (vs 50+ de compendios supremos) para lectura rápida por nuevos desarrolladores.

**NO duplicar**:
Referenciar compendios completos en 00.history/ para detalles profundos.

---

### 2.2 ARQUITECTURA (2 documentos)

#### 2.2.1 README.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Arquitectura/README.md` |
| **Estado** | 🔄 ACTUALIZAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 85% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |
| **Responsable** | CLAUDE |

**Contenido actual**:
- Stack Laravel 10 + Livewire ✅
- Rutas, colas Redis ✅
- Checklist despliegue ✅

**Gaps identificados**:
- Stack desactualizado (dice Laravel 10, real: Laravel 12)
- No menciona PHP 8.2+ (dice 8.3 en algunos lados)
- Falta PostgreSQL 9.5 específico
- No documenta dual database (SQLite dev vs PostgreSQL prod)
- No incluye estructura proyecto confirmada (COPILOT)

**Contenido a agregar/actualizar**:
- § 2.1 Stack confirmado (Laravel 12, PHP 8.2+, PostgreSQL 9.5)
- § 2.2 Dual database architecture (selemti vs public)
- § 2.3 Estructura proyecto (COPILOT tree)
- § 3 Convenciones de naming (remover o link a Convenciones.md)
- § 4 WSL configuration (IP 172.24.240.1)

**Fuentes**:
- 00.history/orquestadores/COPILOT/03_COMPENDIO_SUPREMO_COPILOT.md § Arquitectura
- CLAUDE.md (CLAUDE_md context)
- Análisis FASE4 (código confirmado)

---

#### 2.2.2 Convenciones.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Arquitectura/Convenciones.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟢 P2 |
| **Score objetivo** | 90% |
| **Esfuerzo** | 2 horas |
| **Responsable** | CLAUDE |

**Contenido a incluir**:
- § 1 Naming conventions
  - Modelos: PascalCase, singular (Item, Receta)
  - Controladores: PascalCase + Controller (ItemsController)
  - Livewire: PascalCase + module (Inventory/ItemsIndex)
  - Servicios: PascalCase + Service (ReceptionService)
  - Vistas BD: snake_case, vw_ prefix (vw_kardex)
  - Funciones BD: snake_case, fn_ prefix (fn_recipe_cost_at)
- § 2 Code conventions
  - PSR-12 compliance
  - Laravel Pint configuration
  - PHPDoc required
  - Type hints required
- § 3 Database conventions
  - Schemas: selemti (work), public (legacy)
  - Tables: snake_case, plural (items, recetas)
  - Columns: snake_case (item_id, created_at)
  - Foreign keys: table_singular_id (item_id)
- § 4 Frontend conventions
  - Livewire: wire:model.live.debounce.400ms
  - Bootstrap 5 classes (no Tailwind nuevo)
  - Loading states: wire:loading required
- § 5 Git conventions
  - Branch naming: feature/, bugfix/, hotfix/
  - Commit messages: conventional commits
  - PR template

**Fuentes**:
- 00.history/orquestadores/CLAUDE/03_COMPENDIO_SUPREMO_CLAUDE.md § Part VII
- CLAUDE.md § Development Guidelines
- Análisis FASE4 (código existente)

---

### 2.3 BASE DE DATOS (4 documentos NUEVOS)

#### 2.3.1 README.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/BaseDatos/README.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🔴 P0 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 4 horas |
| **Responsable** | CLAUDE |

**Contenido a incluir**:
- § 1 Introducción
  - Esquema selemti vs public
  - PostgreSQL 9.5
  - Estadísticas: 147 tablas, 38 vistas, 37 funciones, 20 triggers
- § 2 Inventario completo
  - Tabla resumen 147 tablas (nombre, registros, size, módulo)
  - Ordenado por size descendente
- § 3 Tablas críticas Top 20
  - Detalle: columnas, relaciones, índices
  - audit_log (224 kB)
  - sesion_cajon (152 kB)
  - items (152 kB)
  - [... 17 más]
- § 4 Tablas por módulo (15 secciones)
  - Inventario: items, mov_inv, inventory_batch, etc.
  - Recetas: receta_cab, receta_det, receta_version, etc.
  - [... 13 módulos más]
- § 5 Foreign Keys y relaciones
  - 100+ FKs documentadas
  - Diagrama ERD simplificado
- § 6 Tablas legacy (35)
  - unidades_medida_legacy
  - [... 34 más]
  - Plan de deprecación
- § 7 Tablas huérfanas (82 sin modelo)
  - Lista completa
  - Prioridad para crear modelos
- § 8 Enlaces a otros docs
  - Funciones.md (37 funciones)
  - Vistas.md (38 vistas)
  - Triggers.md (20 triggers)

**Fuentes**:
- 00.history/auditorias/AUDITORIA_2025_11_13/FASE5_ANALISIS_BD_SELEMTI.md (completo)
- 00.history/orquestadores/COPILOT/03_COMPENDIO_SUPREMO_COPILOT.md § BD
- Query BD directa para stats actuales

---

#### 2.3.2 Funciones.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/BaseDatos/Funciones.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🔴 P0 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 4 horas |
| **Responsable** | CLAUDE |

**Contenido a incluir**:
- § 1 Introducción (37 funciones PL/pgSQL)
- § 2 Funciones críticas SIN documentar (12)
  - § 2.1 fn_recipe_cost_at(recipe_id, fecha)
    - Propósito: Costeo recetas histórico
    - Parámetros: recipe_id int, fecha date
    - Retorna: decimal(10,2)
    - Algoritmo: [explicación]
    - Usado por: RecipeCostingService
    - Ejemplo: SELECT fn_recipe_cost_at(5, '2025-11-01')
  - § 2.2 fn_recipes_using_item(item_id)
    - Propósito: BOM Implosion
    - [... detalle]
  - [... 10 funciones más]
- § 3 Funciones documentadas (25)
  - Lista con referencia a código
- § 4 Funciones por módulo
  - Inventario: 8 funciones
  - Recetas: 6 funciones
  - Caja: 5 funciones
  - [... etc]
- § 5 Dependencias entre funciones
- § 6 Performance considerations
- § 7 Plan de tests unitarios

**Fuentes**:
- FASE5 § 4.3 Funciones críticas
- Query: SELECT * FROM pg_proc WHERE pronamespace = 'selemti'::regnamespace
- Código: app/Services/ que las invocan

---

#### 2.3.3 Vistas.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/BaseDatos/Vistas.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟡 P1 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 3 horas |
| **Responsable** | CLAUDE |

**Contenido a incluir**:
- § 1 Introducción (38 vistas materializadas)
- § 2 Vistas críticas (Top 10)
  - § 2.1 vw_sesion_dpr
    - Propósito: Dashboard cortes caja
    - Columnas: 15+ (sesion_id, terminal_id, ventas, gastos, etc.)
    - Joins: sesion_cajon + precorte + postcorte
    - Usada por: HistoricoCortes.md, API /api/caja/sesiones
    - SQL: [definición]
  - [... 9 vistas más]
- § 3 Vistas por módulo
  - Dashboard: vw_dashboard_* (13 vistas)
  - Caja: vw_sesion_*, vw_conciliacion_* (7 vistas)
  - Inventario: vw_kardex, vw_stock_resumen (5 vistas)
  - Reportes: vw_report_* (8 vistas)
  - [... etc]
- § 4 Refresh policies (materializadas)
- § 5 Performance y índices
- § 6 Plan de deprecación vistas legacy

**Fuentes**:
- FASE5 § 4.2 Vistas
- Query: SELECT * FROM pg_views WHERE schemaname = 'selemti'
- Reports/README.md (vistas de reportes)

---

#### 2.3.4 Triggers.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/BaseDatos/Triggers.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟢 P2 |
| **Score objetivo** | 90% |
| **Esfuerzo** | 1 hora |
| **Responsable** | CLAUDE |

**Contenido a incluir**:
- § 1 Introducción (20 triggers activos)
- § 2 Triggers críticos (Top 5)
  - fn_precorte_after_insert()
  - fn_postcorte_after_insert()
  - fn_audit_trigger()
  - fn_inventory_batch_before_update()
  - trg_items_assign_code
- § 3 Triggers por tabla
  - sesion_cajon: 3 triggers
  - precorte: 2 triggers
  - postcorte: 2 triggers
  - [... etc]
- § 4 Trigger system architecture
- § 5 Auditoría automática
- § 6 Testing triggers

**Fuentes**:
- FASE5 § 4.4 Triggers
- Query: SELECT * FROM pg_trigger
- Código: database/migrations/*_create_triggers.php

---

### 2.4 CATÁLOGOS (1 documento NUEVO)

#### 2.4.1 README.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Catalogos/README.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🔴 P0 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 3 horas |
| **Responsable** | CLAUDE |

**Contenido a incluir**:
- § 1 Introducción (catálogos maestros)
- § 2 Unidades de Medida (UOM)
  - Tabla: cat_unidades
  - Modelo: Unidad.php
  - Livewire: Catalogs/UnidadesIndex.php
  - Conversiones: cat_uom_conversion
  - Sistema de conversión automático
  - Ejemplo: kg → g (factor 1000)
- § 3 Almacenes
  - Tabla: cat_almacenes
  - Modelo: Almacen.php
  - Livewire: Catalogs/AlmacenesIndex.php
  - Relación con sucursales
- § 4 Proveedores
  - Tabla: cat_proveedores
  - Modelo: Proveedor.php
  - Livewire: Catalogs/ProveedoresIndex.php
  - Integración con Purchasing
- § 5 Sucursales
  - Tabla: cat_sucursales
  - Modelo: Sucursal.php
  - Relación con terminales POS
- § 6 Stock Policies
  - Tabla: inv_stock_policy
  - Modelo: StockPolicy.php (⚠️ NO implementado)
  - Livewire: Catalogs/StockPolicyIndex.php
  - Integración con Replenishment (GAP)
- § 7 Categorías Items
  - Tabla: item_categories
  - Relación con items
- § 8 APIs
  - GET /api/unidades
  - GET /api/unidades/conversiones
  - [... etc]

**Fuentes**:
- app/Livewire/Catalogs/ (6 componentes)
- app/Models/Inv/ (modelos catálogos)
- FASE4 (análisis código)

---

### 2.5 SEGURIDAD (1 documento NUEVO)

#### 2.5.1 README.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Seguridad/README.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🔴 P0 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 3 horas |
| **Responsable** | CLAUDE |

**Contenido a incluir**:
- § 1 Introducción
  - Spatie Laravel Permission
  - JWT Authentication (tymon/jwt-auth)
  - Laravel Sanctum
- § 2 Roles del sistema (7 roles)
  - Tabla roles
  - Almacenista, Comprador, Chef, Cajero, Gerente, Controller, Admin
  - Jerarquía de roles
- § 3 Permisos por módulo
  - Tabla: Módulo | Permiso | Roles
  - inventory.* → Almacenista, Admin
  - purchasing.* → Comprador, Admin
  - recipes.* → Chef, Admin
  - [... etc]
- § 4 Policies (Laravel)
  - app/Policies/ (lista de policies)
  - ItemPolicy, RecipePolicy, etc.
  - Métodos: view, create, update, delete
- § 5 Middleware
  - auth, auth:sanctum
  - role:admin, permission:*
- § 6 Auditoría
  - Tabla: audit_log (224 kB)
  - Modelo: Auditoria.php
  - Eventos auditados
  - Retention policy
- § 7 Configuración
  - config/permissions.php
  - Seeder: PermissionsSeeder
- § 8 UI Permisos
  - ⚠️ GUI limitada (GAP)
  - Livewire/People/UsersIndex.php (básico)
  - Plan: crear GUI completa

**Fuentes**:
- app/Policies/
- config/permissions.php
- database/seeders/PermissionsSeeder.php
- FASE4 (análisis código)
- CONTRATO § 7 Usuarios Clave

---

### 2.6 INVENTARIO (8 documentos)

#### 2.6.1 Items.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Inventario/Items.md` |
| **Estado** | ✅ MANTENER |
| **Prioridad** | 🟢 P2 |
| **Score actual** | 95% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 0 horas |

**Comentarios**:
- Documento excelente, bien estructurado
- Alta/gestión catálogo completa
- API bien documentada
- No requiere cambios inmediatos

---

#### 2.6.2 Recepciones.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Inventario/Recepciones.md` |
| **Estado** | 🔄 ACTUALIZAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 90% |
| **Score objetivo** | 98% |
| **Esfuerzo** | 2 horas |

**Gaps identificados**:
- No documenta estados BORRADOR→VALIDADA→POSTEADA (mencionado en COPILOT)
- Falta flujo de validación y aprobación
- No menciona evidencias en aprobaciones

**Contenido a agregar**:
- § 4 Estados y flujo de validación
  - BORRADOR: creación inicial
  - VALIDADA: revisión calidad
  - POSTEADA: movimiento a inventario
- § 5 Aprobaciones y evidencias
- § 6 Gap: implementación parcial (COPILOT § Gaps)

**Fuentes**:
- COPILOT contrato § Gaps
- PLAN_ACTUALIZACION § 3.2 Altos

---

#### 2.6.3 Conteos.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Inventario/Conteos.md` |
| **Estado** | ✅ MANTENER |
| **Prioridad** | 🟢 P2 |
| **Score actual** | 90% |
| **Score objetivo** | 90% |
| **Esfuerzo** | 0 horas |

**Comentarios**:
- Documento bien estructurado
- InventoryCountService documentado
- 5 componentes Livewire cubiertos
- Mínimas mejoras sugeridas en README § Recomendaciones

---

#### 2.6.4 Transferencias.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Inventario/Transferencias.md` |
| **Estado** | 📝 AMPLIAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 75% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 3 horas |

**Gaps identificados**:
- Implementación parcial (COPILOT)
- Estados incompletos (diseño: 5 estados, código: parcial)
- API no expuesta (endpoints pendientes)
- Mocks en UI (Transfers\Index)

**Contenido a agregar/actualizar**:
- § 3 Estados completos (5 estados documentados)
  - SOLICITADA, APROBADA, EN_TRANSITO, RECIBIDA, RECHAZADA
- § 4 TransferService completo (métodos y lógica)
- § 5 API REST (endpoints a exponer)
- § 6 Reemplazar mocks en UI
- § 7 Gap: implementación 75% (COPILOT)

**Fuentes**:
- COPILOT contrato § Gaps Transferencias
- app/Services/Inventory/TransferService.php
- PLAN_ACTUALIZACION § 3.2

---

#### 2.6.5 Mermas.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Inventario/Mermas.md` |
| **Estado** | 📝 AMPLIAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 60% |
| **Score objetivo** | 90% |
| **Esfuerzo** | 2 horas |

**Gaps identificados**:
- UI básica (COPILOT)
- No documenta inventory_wastes
- No documenta perdida_log
- No documenta integración con Producción

**Contenido a agregar/actualizar**:
- § 2 Tablas
  - inventory_wastes
  - perdida_log
  - merma (legacy?)
- § 3 InventoryWaste modelo
- § 4 Integración con Producción
  - production_orders generan mermas
  - Registro automático
- § 5 UI ajustes (wireflows)
- § 6 Catálogo motivos (MERMA_PRODUCCION, DAÑO, etc.)
- § 7 Gap: UI limitada, catalogar motivos

**Fuentes**:
- app/Models/InventoryWaste.php
- COPILOT contrato § Mermas
- README § Recomendaciones Mermas

---

#### 2.6.6 Disponibilidad.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Inventario/Disponibilidad.md` |
| **Estado** | 🔄 ACTUALIZAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 85% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |

**Gaps identificados**:
- No documenta vw_kardex específicamente
- Kardex implícito, debería separarse
- No documenta v_stock_resumen (COPILOT)

**Contenido a agregar/actualizar**:
- § 3 Vistas BD
  - vw_kardex (detalle)
  - v_stock_resumen (conectar a KPIs - COPILOT)
- § 4 KPIs stock real
- § 5 Riesgo "movimiento rápido" (desactivar hasta servicio con permisos)
- § 6 Link a Kardex.md (documento nuevo)

**Fuentes**:
- BaseDatos/Vistas.md § vw_kardex
- README § Recomendaciones Disponibilidad

---

#### 2.6.7 Ajustes.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Inventario/Ajustes.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟡 P1 |
| **Score objetivo** | 90% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (ajustes manuales inventario)
- § 2 Tipos de ajuste
  - AJUSTE_POSITIVO
  - AJUSTE_NEGATIVO
  - AJUSTE_COSTO
- § 3 mov_inv tipo AJUSTE
  - Registro en kardex
  - Motivo requerido
- § 4 InventoryAdjustmentService
  - Métodos: createAdjustment()
  - Validaciones
  - Auditoría
- § 5 UI wireflows
  - Modal ajuste rápido
  - Formulario ajuste completo
- § 6 Permisos
  - inventory.adjustments.create
  - inventory.adjustments.approve
- § 7 Gap: UI no implementada (FASE4 huérfano)

**Fuentes**:
- app/Services/Inventory/InventoryAdjustmentService.php (huérfano FASE4)
- mov_inv (tabla BD)

---

#### 2.6.8 Kardex.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Inventario/Kardex.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟡 P1 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (trazabilidad completa)
- § 2 Tabla mov_inv
  - Columnas: item_id, batch_id, tipo, qty, uom, ref_tipo, ref_id, ts
  - 104 kB size
- § 3 Tipos de movimiento
  - ENTRADA: Recepción, Ajuste+, Transferencia Entrada
  - SALIDA: Consumo POS, Producción, Merma, Ajuste-, Transferencia Salida
- § 4 Vista vw_kardex
  - SQL definition
  - Columnas calculadas
- § 5 Trazabilidad
  - Batch tracking
  - Lotes y caducidad
  - FIFO/FEFO
- § 6 Función fn_movimientos_kardex(item_id, fecha_inicio, fecha_fin)
- § 7 UI Kardex
  - Livewire/Inventory/ItemsIndex.php (pestaña Kardex)
  - Filtros y búsqueda
- § 8 Reportes Kardex

**Fuentes**:
- BaseDatos/README.md § mov_inv
- BaseDatos/Vistas.md § vw_kardex
- BaseDatos/Funciones.md § fn_movimientos_kardex

---

### 2.7 RECETAS (4 documentos)

#### 2.7.1 README.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Recetas/README.md` |
| **Estado** | 🔄 ACTUALIZAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 70% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |

**Gaps identificados**:
- No documenta versionado (mencionado, no detallado)
- No documenta costeo (mencionado, no detallado)
- No documenta mapeo POS (en POS/README)
- Implementación 75% (CLAUDE contrato)

**Contenido a agregar/actualizar**:
- § 4 Versionado (link a Versionado.md)
- § 5 Costeo automático (link a Costeo.md)
- § 6 Mapeo POS (link a Mapeo_POS.md)
- § 7 Comandos
  - recipes:sync-pos
  - recetas:recalcular-costos
- § 8 Gaps: versionado real (NO implementado), habilitar version > 1

**Fuentes**:
- README existente
- COPILOT contrato § Recetas
- PLAN_ACTUALIZACION § 3.2

---

#### 2.7.2 Versionado.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Recetas/Versionado.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟡 P1 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (trazabilidad histórica recetas)
- § 2 Tabla receta_version
  - Estado: existe, 0 registros (COPILOT)
  - Columnas: receta_id, version, created_at, etc.
- § 3 Modelo RecetaVersion.php
  - Existe (COPILOT)
  - Métodos y relaciones
- § 4 Gap crítico: Editor solo version=1
  - Implementación: 40% (COPILOT)
  - UI NO existe
  - Impacto: Sin trazabilidad histórica
- § 5 Diseño de solución
  - UI versionado
  - Flujo crear nueva versión
  - Comparar versiones
  - Restaurar versión anterior
- § 6 Snapshots de costo por versión
- § 7 Plan de implementación (Sprint 2-3)

**Fuentes**:
- COPILOT contrato § Gaps Versionado Recetas
- app/Models/Rec/RecetaVersion.php
- PLAN_ACTUALIZACION § 3.2

---

#### 2.7.3 Costeo.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Recetas/Costeo.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟡 P1 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (costeo automático recetas)
- § 2 RecipeCostingService
  - app/Services/Costing/RecipeCostingService.php
  - Métodos: calculateCost(), snapshot()
- § 3 Función fn_recipe_cost_at(recipe_id, fecha)
  - ⚠️ SIN DOCUMENTAR (FASE5)
  - Propósito: costeo histórico
  - Algoritmo: [explicar]
- § 4 Tablas
  - historial_costos_receta
  - cost_layer
  - item_cost_history (⚠️ verificar existe en todos entornos)
- § 5 Snapshots de costo
  - Job diario
  - Almacenamiento histórico
- § 6 Comando recetas:recalcular-costos
- § 7 Integración con
  - RecipeEditor (mostrar costo en UI)
  - Reportes (análisis de costos)
  - Producción (costo real vs teórico)
- § 8 Gap: función fn_recipe_cost_at SIN documentar (P0)

**Fuentes**:
- app/Services/Costing/RecipeCostingService.php
- BaseDatos/Funciones.md § fn_recipe_cost_at
- README § Recomendaciones Recetas

---

#### 2.7.4 Mapeo_POS.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Recetas/Mapeo_POS.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟡 P1 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (mapeo productos POS → recetas Terrena)
- § 2 Tabla pos_map
  - Estado: existe, 0 registros (COPILOT)
  - Columnas: menu_item_id, receta_id, qty_factor
- § 3 Livewire/Pos/PosMap.php
  - UI mapeo
  - CRUD completo
- § 4 Comando recipes:sync-pos
  - Sincronización automática
  - Detección productos nuevos
- § 5 Integración con POS
  - Consumos automáticos
  - PosConsumptionService usa pos_map
- § 6 Reprocesamiento tickets
  - pos_reprocess_log
  - Comando pos:reprocess
- § 7 Gap: tabla vacía, requiere mapeo inicial

**Fuentes**:
- app/Livewire/Pos/PosMap.php (COPILOT)
- POS/README.md § Mapeo
- PLAN_ACTUALIZACION § 3.2

---

### 2.8 PRODUCCIÓN (3 documentos)

#### 2.8.1 README.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Produccion/README.md` |
| **Estado** | 📝 AMPLIAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 55% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 3 horas |

**Gaps identificados**:
- Implementación 60% (CLAUDE contrato)
- Backend only (COPILOT)
- UI NO existe (GAP crítico)
- ProductionService stub vs real (COPILOT § Gaps)

**Contenido a agregar/actualizar**:
- § 2 ProductionService
  - Distinguir: app/Services/Production/ProductionService.php (stub)
  - vs app/Services/Inventory/ProductionService.php (real)
  - ⚠️ Consolidar en uno solo
- § 3 UI Producción
  - Gap: NO implementada (COPILOT)
  - Panel operativo cocina
  - KDS (Kitchen Display System) existe (Livewire/Kds/Board.php)
- § 4 Órdenes de producción (link a Ordenes.md)
- § 5 Mermas en producción (link a Mermas.md)
- § 6 KPIs rendimiento
  - Gap: NO implementados (COPILOT)
- § 7 Integración con
  - Recetas (BOM explosion)
  - Inventario (consumos)
  - Replenishment (sugerencias)
- § 8 Gaps: UI NO existe, servicios duplicados, KPIs NO implementados

**Fuentes**:
- COPILOT contrato § Producción
- README existente
- README § Recomendaciones Producción

---

#### 2.8.2 Ordenes.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Produccion/Ordenes.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟡 P1 |
| **Score objetivo** | 90% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (órdenes de producción)
- § 2 Tabla production_orders
  - Estado: existe, 0 registros (COPILOT)
  - Columnas: id, receta_id, qty, status, fecha_produccion, etc.
- § 3 Tabla op_produccion_cab
  - Estado: existe, 0 registros (COPILOT)
  - Relación con production_orders (¿duplicado?)
- § 4 ProductionService (real: Inventory/)
  - Métodos: createOrder(), processOrder(), closeOrder()
  - Consumos a inventario
  - Salidas a kardex
  - Mermas
- § 5 Estados de orden
  - PENDIENTE, EN_PROCESO, COMPLETADA, CANCELADA
- § 6 Integración con
  - Recetas (BOM explosion)
  - Inventario (mov_inv tipo PRODUCCION)
  - Mermas (inventory_wastes)
- § 7 API /api/production/batch/*
  - Estado: implementado (README)
  - Validar permisos production.batch.*
- § 8 Gap: tablas vacías, UI NO existe

**Fuentes**:
- app/Services/Inventory/ProductionService.php
- COPILOT contrato § BD production_orders
- README § APIs

---

#### 2.8.3 Mermas.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Produccion/Mermas.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟡 P1 |
| **Score objetivo** | 90% |
| **Esfuerzo** | 1 hora |

**Contenido a incluir**:
- § 1 Introducción (mermas en producción)
- § 2 Diferencia con Inventario/Mermas.md
  - Inventario: mermas generales
  - Producción: mermas específicas de producción
- § 3 Registro automático
  - production_orders generan inventory_wastes
  - ProductionService registra mermas
- § 4 Cálculo rendimiento real vs teórico
- § 5 Función fn_receta_rendimiento(receta_id)
  - ⚠️ Verificar existe
- § 6 Reportes mermas producción
- § 7 Gap: UI limitada, catalogar motivos específicos producción

**Fuentes**:
- Inventario/Mermas.md (base)
- README § Recomendaciones Mermas
- PLAN_ACTUALIZACION § 3.2

---

### 2.9 PURCHASING (3 documentos)

#### 2.9.1 README.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Purchasing/README.md` |
| **Estado** | 🔄 ACTUALIZAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 85% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |

**Gaps identificados**:
- Motor Replenishment (mencionado, no detallado)
- ReceivingService vs ReceptionService (duplicado FASE4)
- Middleware auth:sanctum falta en /api/purchasing/suggestions* (README § Recomendaciones)
- UI cotizaciones (NO implementada - README § Recomendaciones)

**Contenido a agregar/actualizar**:
- § 6 Motor Replenishment (link a Replenishment.md)
- § 7 Recepciones compras (link a Recepciones_Compras.md)
- § 8 Middleware auth:sanctum
  - Agregar a /api/purchasing/suggestions*
  - Verificar otros endpoints
- § 9 UI cotizaciones
  - Gap: NO implementada
  - Plan: crear antes habilitar flujo completo
- § 10 Gaps: motor replenishment, servicios duplicados, UI cotizaciones

**Fuentes**:
- README existente
- README § Recomendaciones Purchasing
- COPILOT contrato § Gaps Replenishment

---

#### 2.9.2 Replenishment.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Purchasing/Replenishment.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🔴 P0 (GAP CRÍTICO) |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (motor sugerencias reabastecimiento)
- § 2 Gap crítico 🔴
  - BD: inv_stock_policy vacía (COPILOT)
  - Código: NO existe (COPILOT)
  - UI: NO existe (COPILOT)
  - Impacto: Funcionalidad core ausente
  - Prioridad: P0 (COPILOT)
- § 3 Tabla inv_stock_policy
  - Estado: existe, 0 registros
  - Columnas: item_id, almacen_id, min_qty, max_qty, reorder_point
  - Debe poblarse manualmente
- § 4 Tabla replenishment_suggestions
  - 96 kB (CLAUDE contrato § BD)
  - Generada por motor
- § 5 PurchasingService (motor)
  - app/Services/Purchasing/PurchasingService.php
  - Método: generateSuggestions()
  - Algoritmo: min/max, consumo promedio, lead time
- § 6 API /api/purchasing/suggestions*
  - ⚠️ Falta middleware auth:sanctum (README)
- § 7 Replenishment dashboard
  - Vista: vw_replenishment_dashboard (sin datos - COPILOT)
  - UI: NO implementada
- § 8 Integración con
  - Inventario (stock actual)
  - Catálogos (stock policies)
  - Purchasing (crear solicitudes automáticas)
- § 9 Plan de implementación (Sprint 1-2)

**Fuentes**:
- COPILOT contrato § Gap Crítico Motor Replenishment
- app/Services/Purchasing/PurchasingService.php
- README § Recomendaciones

---

#### 2.9.3 Recepciones_Compras.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Purchasing/Recepciones_Compras.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟢 P2 |
| **Score objetivo** | 90% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (recepciones de compras)
- § 2 Duplicación de servicios (GAP)
  - ReceptionService (app/Services/Inventory/)
  - ReceivingService (app/Services/Purchasing/)
  - COPILOT § Gaps: Confusión, mantenimiento
- § 3 ReceptionService (Inventario)
  - Usado por: Inventario/Recepciones.md
  - Crea: recepcion_cab, recepcion_det, inventory_batch, mov_inv
- § 4 ReceivingService (Purchasing)
  - Usado por: Purchasing módulo
  - ¿Diferencia con ReceptionService?
  - COPILOT: ReceivingService duplicado
- § 5 Consolidación requerida
  - Decisión: ¿cuál mantener?
  - Recomendación: ReceptionService (más completo)
  - ReceivingService → deprecar o wrapper
- § 6 Devoluciones
  - ReturnService (incompleto - README § Recomendaciones)
  - Plan: completar antes habilitar flujo
- § 7 Plan de consolidación (Sprint 1)

**Fuentes**:
- FASE4 § Código duplicado
- COPILOT contrato § Gaps Servicios duplicados
- app/Services/Inventory/ReceptionService.php
- app/Services/Purchasing/ReceivingService.php

---

### 2.10 POS (2 documentos)

#### 2.10.1 README.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/POS/README.md` |
| **Estado** | 📝 AMPLIAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 60% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 3 horas |

**Gaps identificados**:
- Implementación 70% (CLAUDE contrato)
- PosConsumptionService (mencionado, no detallado)
- Endpoints NO registrados en routes/api.php (README § Recomendaciones)
- Formularios Livewire (campos obsoletos - README § Recomendaciones)
- Motivos/evidencias al reprocesar tickets (falta obligar - README § Recomendaciones)

**Contenido a agregar/actualizar**:
- § 4 Consumos (link a Consumos.md)
- § 5 PosConsumptionService triplicado (GAP CRÍTICO)
  - 3 ubicaciones (FASE4, CLAUDE contrato)
  - Plan consolidación (Sprint 1)
- § 6 Endpoints PosConsumptionController
  - Gap: NO registrados en routes/api.php
  - Plan: registrar antes exponer módulo
- § 7 Reprocesamiento tickets
  - pos_reprocess_log
  - Comando pos:reprocess
  - Gap: obligar motivos/evidencias
- § 8 Formularios Livewire
  - Limpiar campos obsoletos
- § 9 Gaps: servicios triplicados, endpoints no expuestos, UI limitada

**Fuentes**:
- README existente
- README § Recomendaciones POS
- FASE4 § PosConsumptionService x3

---

#### 2.10.2 Consumos.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/POS/Consumos.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟡 P1 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 3 horas |

**Contenido a incluir**:
- § 1 Introducción (consumo automático inventario desde POS)
- § 2 Gap crítico: PosConsumptionService x3 🔴
  - app/Services/Pos/PosConsumptionService.php
  - app/Services/Inventory/PosConsumptionService.php
  - app/Services/Legacy/PosConsumptionService.php
  - FASE4, CLAUDE contrato § Código duplicado crítico
  - Impacto: Lógica inconsistente entre versiones
  - Riesgo: Errores en cálculo consumos
  - Prioridad: P0
- § 3 Consolidación (Sprint 1)
  - Decisión: mantener app/Services/Pos/
  - Deprecar: Inventory/ y Legacy/
- § 4 Tablas
  - inv_consumo_pos (COPILOT)
  - inv_consumo_pos_det
- § 5 Función fn_expandir_consumo_ticket(ticket_id)
  - ⚠️ SIN DOCUMENTAR (FASE5)
  - Propósito: expansión consumo POS
  - Algoritmo: [explicar]
- § 6 Flujo completo
  1. Ticket cerrado en Floreant POS (public schema)
  2. Trigger o job detecta nuevo ticket
  3. PosConsumptionService procesa
  4. Usa pos_map (menu_item_id → receta_id)
  5. Explode receta (BOM explosion)
  6. Registra consumos en mov_inv
  7. Actualiza inv_consumo_pos
- § 7 PosConsumptionController
  - API endpoints (NO registrados - POS/README § Recomendaciones)
  - Plan: registrar en routes/api.php
- § 8 DTO Pattern
  - PosConsumptionResult
  - PosConsumptionDiagnostics
- § 9 Repositorio
  - PosConsumptionRepository (FASE4)
- § 10 Plan consolidación (Sprint 1 - 4h)

**Fuentes**:
- FASE4 § PosConsumptionService triplicado
- CLAUDE contrato § Riesgos Críticos
- BaseDatos/Funciones.md § fn_expandir_consumo_ticket
- app/Services/Pos/PosConsumptionService.php

---

### 2.11 CAJA (2 documentos)

#### 2.11.1 HistoricoCortes.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Caja/HistoricoCortes.md` |
| **Estado** | ✅ MANTENER |
| **Prioridad** | 🟢 P2 |
| **Score actual** | 95% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 0 horas |

**Comentarios**:
- Documento excelente
- Módulo Caja 95% impl, 95% docs (CLAUDE contrato)
- No requiere cambios inmediatos

---

#### 2.11.2 REDIRECCION_DETALLE_A_WIZARD.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Caja/REDIRECCION_DETALLE_A_WIZARD.md` |
| **Estado** | ✅ MANTENER |
| **Prioridad** | 🟢 P2 |
| **Score actual** | 90% |
| **Score objetivo** | 90% |
| **Esfuerzo** | 0 horas |

**Comentarios**:
- Documento técnico específico
- No requiere cambios

---

### 2.12 FINANZAS (3 documentos)

#### 2.12.1 README.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Finanzas/README.md` |
| **Estado** | 📝 AMPLIAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 70% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |

**Gaps identificados**:
- Implementación 65% (CLAUDE contrato)
- DailyCloseService (mencionado, no detallado - README § Recomendaciones)
- Middleware desactivado en /api/caja/* (README § Recomendaciones)
- Sincronización Caja Chica/Histórico cortes (README § Recomendaciones)

**Contenido a agregar/actualizar**:
- § 3 Caja Chica (link a CajaChica.md)
- § 4 Cortes de caja (link a Cortes.md)
- § 5 DailyCloseService
  - Cierre diario unificado
  - Sincronización módulos
- § 6 Middleware
  - Gap: desactivado en /api/caja/*
  - Plan: reactivar middleware auth:sanctum
- § 7 Permisos
  - cashfund.*, caja.* (formalizar)
- § 8 Sincronización módulos
  - Caja Chica + Histórico cortes + DailyCloseService
  - Evitar divergencias
- § 9 Gaps: middleware desactivado, sincronización módulos

**Fuentes**:
- README existente
- README § Recomendaciones Finanzas
- CLAUDE contrato § Finanzas 65%

---

#### 2.12.2 CajaChica.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Finanzas/CajaChica.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟢 P2 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (fondo fijo caja chica)
- § 2 Módulo excelente ✅
  - Implementación: 100% (CLAUDE contrato)
  - Documentación: 100% (13 docs)
  - Patrón a seguir
- § 3 Modelos
  - CashFund
  - CashFundMovement
  - CashFundSettlement
- § 4 Servicio
  - CashFundService (robusto)
  - Métodos: create(), addMovement(), settle(), approve()
- § 5 Livewire (6 componentes)
  - Index, Detail, Create, Movements, Settlements, Approvals
  - UI consistente Bootstrap 5
- § 6 Tablas BD
  - cash_funds (96 kB, 1 registro - CLAUDE contrato)
  - cash_fund_movements (0 registros)
  - Triggers activos
- § 7 Máquina de estados
  - ACTIVO, CERRADO, LIQUIDADO
  - Transiciones claras
- § 8 Auditoría completa
  - audit_log
  - Trazabilidad 100%
- § 9 Permisos
  - cashfund.view, cashfund.create, cashfund.approve, etc.
- § 10 Referencia: docs históricos (13 docs en 00.history/)

**Fuentes**:
- app/Livewire/CashFund/ (6 componentes)
- app/Services/Cash/CashFundService.php
- CLAUDE contrato § 2.1 Módulo Caja Chica 100%

---

#### 2.12.3 Cortes.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Finanzas/Cortes.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟢 P2 |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (cierre diario caja)
- § 2 Tablas
  - precorte (33 registros - COPILOT)
  - postcorte (27 registros)
  - sesion_cajon (152 kB, 132 registros - CLAUDE/COPILOT)
- § 3 Vista vw_sesion_dpr
  - Dashboard cortes
  - 15+ columnas
  - Link a BaseDatos/Vistas.md
- § 4 API /api/caja/*
  - Precorte, Postcorte, Sesiones, Alertas
  - Controllers: Api/Caja/ (3 controladores)
  - Gap: middleware desactivado
- § 5 Triggers
  - fn_precorte_after_insert() (⚠️ SIN DOC - FASE5)
  - fn_postcorte_after_insert() (⚠️ SIN DOC)
  - Actualiza sesion_cajon
  - Link a BaseDatos/Triggers.md
- § 6 DailyCloseService
  - Cierre unificado
  - Sincronización con Caja Chica
- § 7 Wizard UI
  - _wizard_modals.blade.php
  - Flujo intuitivo
- § 8 Aprobaciones multinivel
  - Gerente → Controller
  - Permisos caja.postcorte.approve
- § 9 Histórico (link a Caja/HistoricoCortes.md)

**Fuentes**:
- app/Http/Controllers/Api/Caja/ (3 controllers)
- BaseDatos/Vistas.md § vw_sesion_dpr
- BaseDatos/Triggers.md § fn_precorte/postcorte_after_insert
- Finanzas/README.md § DailyCloseService

---

### 2.13 REPORTS (3 documentos)

#### 2.13.1 README.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Reports/README.md` |
| **Estado** | ✅ MANTENER |
| **Prioridad** | 🟢 P2 |
| **Score actual** | 88% |
| **Score objetivo** | 90% |
| **Esfuerzo** | 0 horas |

**Comentarios**:
- Módulo excelente: 90% impl, 90% docs (CLAUDE contrato)
- Bien estructurado
- Mínimas mejoras: agregar links a KPIs.md y Ventas.md cuando se creen

---

#### 2.13.2 KPIs.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Reports/KPIs.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟢 P2 |
| **Score objetivo** | 90% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (KPIs tiempo real)
- § 2 Vistas dashboard (13 vistas)
  - vw_dashboard_* (COPILOT)
  - Link a BaseDatos/Vistas.md
- § 3 Dashboards interactivos
  - ReportsController
  - Livewire/Reports/ (2 componentes)
- § 4 KPIs por módulo
  - Inventario: stock, rotación, mermas
  - Ventas: tickets, ingresos, top productos
  - Producción: órdenes, rendimiento, mermas
  - Compras: órdenes, recepciones, lead time
  - Caja: cortes, variances, arqueos
- § 5 Funciones SQL
  - f_* (funciones de reportes - README)
- § 6 Filtros avanzados
  - Fecha, sucursal, usuario, categoría
- § 7 Actualización
  - Tiempo real vs materializadas
  - Refresh policies

**Fuentes**:
- Reports/README.md
- BaseDatos/Vistas.md § vw_dashboard_*
- app/Http/Controllers/Reports/ReportsController.php

---

#### 2.13.3 Ventas.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Reports/Ventas.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🟢 P2 |
| **Score objetivo** | 90% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (reportes ventas)
- § 2 Rutas /reports/sales/*
  - SalesDetailController (README)
  - BaseReportController
- § 3 Vistas
  - vw_report_* (8 vistas - COPILOT)
  - vw_report_sales_detail
  - Link a BaseDatos/Vistas.md
- § 4 Exports
  - PDF: BaseReportController
  - XLSX: Exports/ classes
  - Limitados (README § Gaps)
- § 5 Funciones SQL
  - f_* para reportes ventas
  - Agregaciones y cálculos
- § 6 Integración con POS
  - Tickets desde public.ticket
  - Consumos desde inv_consumo_pos
- § 7 Análisis
  - Ventas por producto
  - Ventas por categoría
  - Ventas por terminal
  - Ventas por usuario
  - Tendencias y comparativas

**Fuentes**:
- Reports/README.md
- app/Http/Controllers/Reports/SalesDetailController.php
- BaseDatos/Vistas.md § vw_report_*

---

### 2.14 FRONTEND (3 documentos)

#### 2.14.1 Layout.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Frontend/Layout.md` |
| **Estado** | 🔄 ACTUALIZAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 85% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 1 hora |

**Gaps identificados**:
- Falta documentar patrones Bootstrap 5 (migración de Tailwind)
- Falta documentar slots y componentes
- No menciona TerrenaHasPerm (permisos async)

**Contenido a agregar/actualizar**:
- § 4 Patrones Bootstrap 5
  - Cards, modals, badges, toasts
  - Grid system
  - Utilities
- § 5 Slots y secciones
  - @yield, @section
  - Layouts anidados
- § 6 TerrenaHasPerm
  - Permisos async
  - Layout shift (GAP FASE6)
  - Solución: skeleton loaders
- § 7 Migración Tailwind → Bootstrap
  - Estado: en progreso
  - Deprecar Tailwind completamente

**Fuentes**:
- Frontend/Layout.md existente
- README § Recomendaciones Frontend
- FASE6 § Gap Layout shift

---

#### 2.14.2 Componentes.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Frontend/Componentes.md` |
| **Estado** | 🔄 ACTUALIZAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 80% |
| **Score objetivo** | 95% |
| **Esfuerzo** | 2 horas |

**Gaps identificados**:
- No documenta gaps UX FASE6
- Falta catálogo completo componentes <x-ui.*>
- No documenta design system

**Contenido a agregar/actualizar**:
- § 6 Gaps UX (link a GapsUX_Criticos.md)
- § 7 Catálogo completo
  - <x-ui.card>
  - <x-ui.modal>
  - <x-ui.badge>
  - <x-ui.toast>
  - <x-ui.button>
  - [... todos los componentes]
- § 8 Design system activo
  - Colores, tipografía, espaciado
  - Consistencia visual
- § 9 Política actualizaciones
  - Registro nuevos componentes
  - Deprecación componentes legacy

**Fuentes**:
- Frontend/Componentes.md existente
- resources/views/components/ui/ (inventario completo)
- README § Recomendaciones Frontend

---

#### 2.14.3 GapsUX_Criticos.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Frontend/GapsUX_Criticos.md` |
| **Estado** | ⭐ CREAR |
| **Prioridad** | 🔴 P0 |
| **Score objetivo** | 98% |
| **Esfuerzo** | 2 horas |

**Contenido a incluir**:
- § 1 Introducción (UX score 6.5/10 → 8.0/10)
- § 2 Gap 1: Forms sin loading states 🔴
  - Impacto: 40 formularios
  - Problema: clicks duplicados, frustración
  - Patrón actual: sin feedback
  - Patrón esperado: wire:loading con spinner
  - Componentes afectados: [lista 40]
  - Solución: Sprint 1 (4h)
  - Esfuerzo: 40 forms × 6 min = 4h
- § 3 Gap 2: Notificaciones rotas 🔴
  - Impacto: 70% falla silenciosa
  - Problema: 3 patrones incompatibles
  - Fragmentación: toastr (12), SweetAlert2 (8), alert() (5), sin notif (17)
  - Solución: Sistema unificado Toast Bootstrap 5
  - Esfuerzo: 6h (Sprint 1)
- § 4 Gap 3: Confirmaciones delete 🔴
  - Impacto: 50% sin confirmación (15 componentes)
  - Problema: Riesgo pérdida datos
  - Componentes sin confirmación: [lista 15]
  - Solución: Modal confirmación estándar
  - Esfuerzo: 4h (Sprint 1)
- § 5 Otros gaps UX
  - Layout shift permisos async (4h)
  - Modales fragmentados (2h)
- § 6 Roadmap solución (Sprint 1 - 24h)
  - US-1.1: Loading states (4h)
  - US-1.2: Toasts unificados (6h)
  - US-1.3: Confirmaciones delete (4h)
  - US-1.4: Layout shift (4h)
  - US-1.5: Modales (2h)
  - US-1.6: Consolidar PosConsumptionService (4h)
- § 7 Resultado esperado: UX 7.0/10
- § 8 Referencias
  - FASE6 completo
  - BACKLOG_SPRINTS_V4.0.md Sprint 1

**Fuentes**:
- 00.history/auditorias/AUDITORIA_2025_11_13/FASE6_EVALUACION_UI_UX.md (completo)
- CODEX compendio § Brechas UX
- BACKLOG Sprint 1

---

### 2.15 GUÍA (1 documento)

#### 2.15.1 Stack.md

| Campo | Valor |
|-------|-------|
| **Ruta** | `docs/V4.0/Guia/Stack.md` |
| **Estado** | 🔄 ACTUALIZAR |
| **Prioridad** | 🟡 P1 |
| **Score actual** | 90% |
| **Score objetivo** | 98% |
| **Esfuerzo** | 1 hora |

**Gaps identificados**:
- Versiones no confirmadas (dice Laravel 10, real: Laravel 12)
- Falta PostgreSQL 9.5 específico
- No menciona dual database

**Contenido a agregar/actualizar**:
- § 2 Versiones confirmadas
  - Laravel 12 (no 10)
  - PHP 8.2+ (no 8.3)
  - PostgreSQL 9.5 (específico)
  - Livewire 3.7 beta
  - Bootstrap 5.3
- § 3 Dual database
  - SQLite: dev (opcional)
  - PostgreSQL: prod (selemti + public)
- § 4 Comandos actualizados
  - composer dev (concurrently)
  - php artisan pail (logs)

**Fuentes**:
- Guia/Stack.md existente
- COPILOT compendio § Stack Tecnológico Real
- CLAUDE.md context

---

## 3. RESUMEN POR PRIORIDAD

### 3.1 Prioridad P0 - Crítica (9 documentos - 20 horas)

| # | Documento | Esfuerzo | Sprint |
|---|-----------|----------|--------|
| 1 | 00_Orquestador/CONTRATO_SISTEMA_TERRENA_v3.md | 3h | Fase 1 |
| 2 | 00_Orquestador/MATRIZ_ALINEACION_V4.0.md | 2h | Fase 1 |
| 3 | 00_Orquestador/BACKLOG_SPRINTS_V4.0.md | 2h | Fase 1 |
| 4 | 00_Orquestador/COMPENDIO_TECNICO.md | 1h | Fase 1 |
| 5 | BaseDatos/README.md | 4h | Fase 2 |
| 6 | BaseDatos/Funciones.md | 4h | Fase 2 |
| 7 | Catalogos/README.md | 3h | Fase 3 |
| 8 | Seguridad/README.md | 3h | Fase 3 |
| 9 | Frontend/GapsUX_Criticos.md | 2h | Fase 3 |
| **TOTAL P0** | **24 horas** | **Semana 1-2** |

### 3.2 Prioridad P1 - Alta (15 documentos - 35 horas)

| # | Documento | Esfuerzo | Sprint |
|---|-----------|----------|--------|
| 10 | README.md | 1h | Fase 5 |
| 11 | Arquitectura/README.md | 2h | Fase 5 |
| 12 | BaseDatos/Vistas.md | 3h | Fase 2 |
| 13 | Inventario/Recepciones.md | 2h | Fase 3 |
| 14 | Inventario/Transferencias.md | 3h | Fase 4 |
| 15 | Inventario/Mermas.md | 2h | Fase 4 |
| 16 | Inventario/Disponibilidad.md | 2h | Fase 4 |
| 17 | Inventario/Ajustes.md | 2h | Fase 4 |
| 18 | Inventario/Kardex.md | 2h | Fase 4 |
| 19 | Recetas/README.md | 2h | Fase 3 |
| 20 | Recetas/Versionado.md | 2h | Fase 4 |
| 21 | Recetas/Costeo.md | 2h | Fase 4 |
| 22 | Recetas/Mapeo_POS.md | 2h | Fase 4 |
| 23 | Produccion/README.md | 3h | Fase 3 |
| 24 | Produccion/Ordenes.md | 2h | Fase 4 |
| **TOTAL P1** | **32 horas** | **Semana 1-3** |

### 3.3 Prioridad P2 - Media (20 documentos - 24 horas)

| # | Documento | Esfuerzo | Sprint |
|---|-----------|----------|--------|
| 25 | Arquitectura/Convenciones.md | 2h | Fase 5 |
| 26 | BaseDatos/Triggers.md | 1h | Fase 2 |
| 27 | Produccion/Mermas.md | 1h | Fase 4 |
| 28 | Purchasing/README.md | 2h | Fase 3 |
| 29 | Purchasing/Replenishment.md | 2h | Fase 4 |
| 30 | Purchasing/Recepciones_Compras.md | 2h | Fase 4 |
| 31 | POS/README.md | 3h | Fase 3 |
| 32 | POS/Consumos.md | 3h | Fase 4 |
| 33 | Finanzas/README.md | 2h | Fase 3 |
| 34 | Finanzas/CajaChica.md | 2h | Fase 5 |
| 35 | Finanzas/Cortes.md | 2h | Fase 5 |
| 36 | Reports/KPIs.md | 2h | Fase 5 |
| 37 | Reports/Ventas.md | 2h | Fase 5 |
| 38 | Frontend/Layout.md | 1h | Fase 5 |
| 39 | Frontend/Componentes.md | 2h | Fase 5 |
| 40 | Guia/Stack.md | 1h | Fase 5 |
| **TOTAL P2** | **30 horas** | **Semana 2-3** |

### 3.4 Mantener (4 documentos - 0 horas)

| # | Documento | Estado |
|---|-----------|--------|
| 41 | Inventario/Items.md | ✅ Excelente |
| 42 | Inventario/Conteos.md | ✅ Bien |
| 43 | Caja/HistoricoCortes.md | ✅ Excelente |
| 44 | Caja/REDIRECCION_DETALLE_A_WIZARD.md | ✅ Bien |
| 45 | Reports/README.md | ✅ Excelente |

---

## 4. CRONOGRAMA DE EJECUCIÓN

| Fase | Docs | Esfuerzo | Prioridad | Semana |
|------|------|----------|-----------|--------|
| **Fase 1: Orquestador** | 4 | 8h | P0 | 1 |
| **Fase 2: Base Datos** | 4 | 12h | P0-P1 | 1 |
| **Fase 3: Módulos Críticos** | 6 | 16h | P0-P1 | 1-2 |
| **Fase 4: Sub-módulos** | 12 | 24h | P1-P2 | 2 |
| **Fase 5: Refinamiento** | 8 | 16h | P1-P2 | 3 |
| **TOTAL** | **34 nuevos** | **76h** | - | **3 semanas** |

**Nota**: 44 documentos totales = 10 existentes (mantener/actualizar) + 34 nuevos (crear/ampliar)

---

## 5. CRITERIOS DE VALIDACIÓN

### 5.1 Por Documento

| Criterio | Verificación |
|----------|--------------|
| **Completitud** | Todas las secciones del template presentes |
| **Trazabilidad código** | Enlaces a archivos reales (app/, resources/) |
| **Trazabilidad BD** | Enlaces a tablas/vistas/funciones (selemti.*) |
| **Formato consistente** | Sigue patrón Compendio Supremo |
| **Sin contradicciones** | Alineado con otros documentos V4.0 |
| **Referencias agentes** | Reconoce aportes CLAUDE, QWEN, CODEX, COPILOT |

### 5.2 Por Módulo

| Criterio | Verificación |
|----------|--------------|
| **Cobertura 100%** | README + sub-módulos documentados |
| **APIs documentadas** | Todos los endpoints listados |
| **Modelos documentados** | Todos los modelos Eloquent listados |
| **Livewire documentado** | Todos los componentes listados |
| **BD documentada** | Todas las tablas/vistas/funciones del módulo |
| **Gaps identificados** | Todos los gaps FASE1-6 mencionados |

### 5.3 Global

| Métrica | Meta | Medición |
|---------|------|----------|
| **Cobertura documental** | ≥ 94% | 44 docs / 44 objetivo |
| **Cobertura módulos** | 15/15 (100%) | Todos con README |
| **Funciones BD documentadas** | ≥ 90% | 33/37 funciones |
| **Vistas BD documentadas** | 100% | 38/38 vistas |
| **Duplicados resueltos** | 0 | Fusión completada |
| **Referencias agentes** | 4/4 | Todos mencionados |

---

## 6. PRÓXIMOS PASOS

### 6.1 Aprobación (1 hora)
- [ ] Revisar matriz con stakeholders
- [ ] Aprobar estructura 44 documentos
- [ ] Aprobar prioridades P0/P1/P2
- [ ] Confirmar roadmap 3 semanas (76h)

### 6.2 Inicio Fase 1 (8 horas - Semana 1)
- [ ] Actualizar CONTRATO_SISTEMA_TERRENA_v3.md (3h)
- [ ] Crear MATRIZ_ALINEACION_V4.0.md (2h)
- [ ] Crear BACKLOG_SPRINTS_V4.0.md (2h)
- [ ] Crear COMPENDIO_TECNICO.md (1h)

### 6.3 Comunicación
- [ ] Notificar a QWEN, CODEX, COPILOT del inicio
- [ ] Solicitar revisión de docs fusionados
- [ ] Establecer canal feedback durante ejecución

---

**FIN MATRIZ DOCUMENTAL ACTUALIZADA V4.0**
**Próxima acción**: Iniciar Fase 1 (Orquestador - 8 horas) tras aprobación
