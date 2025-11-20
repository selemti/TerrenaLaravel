# MATRIZ DE ALINEACIÓN INICIAL v2 - CLAUDE

**Orquestador**: Claude Code
**Fecha**: 14 Noviembre 2025
**Fuente**: FASE1-FASE6 Auditoría

---

## 1. ESTADO GLOBAL DEL SISTEMA

| Dimensión | Estado Actual | Objetivo | Gap | Prioridad |
|-----------|---------------|----------|-----|-----------|
| **Documentación** | 76% (19/44 docs) | 94% (44 docs) | 25 archivos | 🔴 CRÍTICA |
| **Código** | 61% documentado | 80% documentado | 189 archivos huérfanos | 🔴 CRÍTICA |
| **Base de Datos** | 90% alineación | 95% alineación | 12 funciones críticas | 🟡 ALTA |
| **UI/UX** | 6.5/10 score | 8.0/10 score | 3 gaps críticos | 🔴 CRÍTICA |
| **Tests** | ~30% cobertura | 70% cobertura | +40% cobertura | 🟡 ALTA |

---

## 2. MATRIZ POR MÓDULO (15 MÓDULOS)

### 2.1 CAJA CHICA (EXCELENTE ⭐⭐⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 100% | 13 docs en /CajaChica/FondoCaja/ | Ninguno |
| **Código** | 100% | CashFund, CashFundService, 6 Livewire | Ninguno |
| **BD** | 100% | cash_funds, cash_fund_movements, triggers | Ninguno |
| **UI** | 90% | 12 vistas completas, Bootstrap 5 | Tooltips menores |
| **Tests** | 80% | Feature tests completos | Browser tests |

**Archivos Clave**:
- docs/CajaChica/FondoCaja/CAJA_CHICA_LIFECYCLE.md
- app/Models/CashFund.php
- app/Services/CashFundService.php
- app/Livewire/CashFund/* (6 componentes)
- selemti.cash_funds (96 kB, 1 registro)

**Próximos Pasos**: Ninguno (modelo ejemplar)

---

### 2.2 CAJA (PRECORTE/POSTCORTE) (EXCELENTE ⭐⭐⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 95% | 3 docs V4.0/Caja/ + wizard | AlertasService sin doc |
| **Código** | 95% | Controllers, wizard, helpers | AlertasService |
| **BD** | 100% | sesion_cajon, precorte, postcorte, triggers | Ninguno |
| **UI** | 85% | Wizard completo, modales | Loading states |
| **Tests** | 75% | Feature tests caja | Integration tests |

**Archivos Clave**:
- docs/V4.0/Caja/* (3 docs)
- app/Http/Controllers/Api/Caja/* (3 controllers)
- app/Helpers/CajaHelper.php
- selemti.sesion_cajon (152 kB, 132 sesiones)
- resources/views/caja/_wizard_modals.blade.php

**Gaps**:
- AlertasService.php sin documentar
- Forms sin loading states
- Tests de integración workflow completo

---

### 2.3 REPORTES (VENTAS) (EXCELENTE ⭐⭐⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 90% | 5 docs Reports/, 77 migraciones | Vistas BD individuales |
| **Código** | 90% | Controladores, servicios | Exportaciones |
| **BD** | 100% | 38 vistas (vw_sesion_dpr, vw_report_*) | Ninguno |
| **UI** | 80% | Dashboards, KPIs | Filtros avanzados |
| **Tests** | 70% | Unit tests vistas | Feature tests |

**Archivos Clave**:
- docs/Reports/RESUMEN_COMPLETO_REPORTES_2025_11_04.md
- docs/Migraciones/MIGRACIONES_COMPLETADAS_2025_11_05.md
- selemti.vw_sesion_dpr, vw_dashboard_*, vw_report_sales_*
- database/migrations/* (77 migraciones UOM)

**Gaps**:
- 10 vistas BD sin doc individual
- Exportaciones avanzadas limitadas
- Feature tests para reportes complejos

---

### 2.4 INVENTARIO (BIEN ⭐⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 80% | 1 doc parcial V4.0/Inventario/ | Lotes, Kardex, Ajustes, Políticas |
| **Código** | 85% | Models, services, Livewire | BatchTracking, Ajustes sin UI |
| **BD** | 90% | items, mov_inv, inventory_batch | Triggers faltantes |
| **UI** | 75% | ItemsIndex, Recepciones, Conteos | Empty states, loading |
| **Tests** | 60% | Unit tests servicios | Feature tests flujos |

**Archivos Clave**:
- docs/V4.0/Inventario/Items.md (parcial)
- app/Models/Inv/* (Item, Batch, MovimientoInventario)
- app/Services/Inventory/ReceptionService.php
- app/Livewire/Inventory/* (ItemsIndex, ReceptionsIndex)
- selemti.items (152 kB, 6 activos), mov_inv (104 kB, 0 registros)

**Gaps Críticos**:
- 4 docs faltantes: Lotes, Kardex, Ajustes, Políticas
- InventoryAdjustmentService.php sin doc
- BatchTrackingService.php sin doc
- 8 componentes Livewire sin doc
- Forms sin loading states
- Empty states sin gráficos

**Próximos Pasos**:
1. Crear docs/V4.0/Inventario/02_LOTES_TRAZABILIDAD.md
2. Crear docs/V4.0/Inventario/03_KARDEX_AJUSTES.md
3. Documentar BatchTrackingService
4. Agregar loading states a forms
5. Mejorar empty states

---

### 2.5 PURCHASING (COMPRAS) (BIEN ⭐⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 85% | 2 docs V4.0/Purchasing/ | Reposición/Replenishment |
| **Código** | 85% | PurchasingService (Codex), 5 Livewire | PurchaseRequest duplicado |
| **BD** | 90% | purchase_requests, purchase_orders | replenishment_suggestions vacía |
| **UI** | 80% | Requests/Index, Create, Detail | Comparación cotizaciones |
| **Tests** | 70% | Unit tests service | Feature tests workflow |

**Archivos Clave**:
- docs/V4.0/Purchasing/01_REQUISICIONES.md
- docs/V4.0/Purchasing/02_ORDENES.md
- app/Models/Purchasing/PurchaseRequest.php (2 ubicaciones!)
- app/Services/Purchasing/PurchasingService.php (Codex)
- app/Livewire/Purchasing/Requests/* (3 componentes)
- selemti.purchase_requests (64 kB), purchase_orders (40 kB)

**Gaps Críticos**:
- PurchaseRequest.php duplicado (app/Models/ y app/Models/Purchasing/)
- Módulo Replenishment no implementado (tabla vacía)
- Doc de Reposición Automática faltante
- Comparación de cotizaciones manual

**Próximos Pasos**:
1. Consolidar PurchaseRequest a Purchasing/
2. Implementar motor Replenishment
3. Crear docs/V4.0/Purchasing/03_REPLENISHMENT.md
4. UI comparación cotizaciones

---

### 2.6 RECETAS (PARCIAL ⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 70% | 1 doc breve (135 líneas) | Versionado, Costeo detallado |
| **Código** | 75% | RecipesIndex, RecipeEditor | Versionado UI, Modificadores UI |
| **BD** | 75% | receta_cab, receta_version, recipe_cost_snapshots | recipe_versions duplicado |
| **UI** | 70% | Editor básico | Versionado, Snapshots |
| **Tests** | 60% | Unit tests | Feature tests costeo |

**Archivos Clave**:
- docs/V4.0/Recetas/README.md (135 líneas, muy breve)
- app/Models/Rec/* (Receta, RecetaDetalle, RecetaVersion)
- app/Livewire/Recipes/* (RecipesIndex, RecipeEditor)
- selemti.receta_cab (56 kB), receta_version (40 kB), recipe_cost_snapshots (32 kB)

**Gaps Críticos**:
- Documentación muy breve (135 líneas para módulo complejo)
- Sistema versionado no documentado
- Naming duplicado: receta_version vs recipe_versions
- RecipeCostSnapshot modelo huérfano
- UI versionado no existe

**Próximos Pasos**:
1. Ampliar docs/V4.0/Recetas/README.md (300+ líneas)
2. Crear docs/V4.0/Recetas/02_VERSIONADO.md
3. Crear docs/V4.0/Recetas/03_COSTEO_DETALLADO.md
4. Consolidar naming BD (receta_version)
5. Documentar RecipeCostSnapshot
6. UI para versionado

---

### 2.7 PRODUCCIÓN (INCOMPLETO ⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 55% | 1 doc breve (100 líneas) | Planificación, Mise en Place, Mermas |
| **Código** | 60% | ProductionService (2 ubicaciones!), models | UI operativa, Livewire |
| **BD** | 70% | production_orders, op_cab, op_insumo | 4 tablas vacías sin uso |
| **UI** | 40% | NO existe panel operativo | Todo el módulo UI |
| **Tests** | 50% | Unit tests parciales | Feature tests |

**Archivos Clave**:
- docs/V4.0/Produccion/README.md (100 líneas, muy breve)
- app/Models/OrdenProduccion.php, ProductionSchedule.php
- app/Services/ProductionService.php (2 ubicaciones!)
- selemti.production_orders (72 kB), op_cab (30 kB)

**Gaps Críticos**:
- ProductionService.php DUPLICADO (2 ubicaciones)
- Documentación mínima (100 líneas)
- UI operativa NO EXISTE
- 4 tablas sin uso (op_produccion_cab, sol_prod_*, prod_*)
- Módulo 60% implementado

**Próximos Pasos**:
1. Consolidar ProductionService (eliminar duplicado)
2. Ampliar docs/V4.0/Produccion/README.md (300+ líneas)
3. Crear docs/V4.0/Produccion/02_MISE_EN_PLACE.md
4. Crear docs/V4.0/Produccion/03_MERMAS_RENDIMIENTOS.md
5. Implementar UI completa (panel operativo)
6. Eliminar tablas sin uso

---

### 2.8 VENTAS (POS-RECETAS) (BIEN ⭐⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 75% | 1 doc diagnóstico | Mapeo POS-Recetas, Snapshots |
| **Código** | 80% | PosConsumptionService (3 ubicaciones!), repos | Servicio triplicado |
| **BD** | 80% | pos_map, recipe_cost_snapshots | Modelos huérfanos |
| **UI** | 75% | PosMap.php | Consumo sin UI detallada |
| **Tests** | 65% | Unit tests | Integration tests |

**Archivos Clave**:
- docs/Ventas/DIAGNOSTICO_TICKETS_06NOV2025.md
- app/Services/PosConsumptionService.php (3 ubicaciones!)
- app/Models/PosMap.php (huérfano), RecipeCostSnapshot.php (huérfano)
- app/Repositories/Pos/* (5 repositorios)
- selemti.pos_map (40 kB), ticket_det_consumo (40 kB)

**Gaps Críticos**:
- PosConsumptionService.php TRIPLICADO (CRÍTICO)
- PosMap modelo huérfano
- RecipeCostSnapshot modelo huérfano
- 5 repositorios sin documentar

**Próximos Pasos**:
1. Consolidar PosConsumptionService (3 → 1 ubicación)
2. Crear docs/V4.0/Ventas/01_CONSUMO_POS_RECETAS.md
3. Crear docs/V4.0/Ventas/02_SNAPSHOTS_COSTOS.md
4. Documentar PosMap y RecipeCostSnapshot
5. Documentar 5 repositorios

---

### 2.9 POS (INTEGRACIÓN) (PARCIAL ⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 60% | 1 doc breve (110 líneas) | Sincronización, Repositorios, Tickets |
| **Código** | 70% | Models, repos, services | 5 repos sin doc, sync sin doc |
| **BD** | 75% | pos_*, menu_*, ticket_* | 10 tablas sin modelo |
| **UI** | 60% | Básica | Sync, mapeo avanzado |
| **Tests** | 55% | Unit tests | Feature tests |

**Archivos Clave**:
- docs/V4.0/POS/README.md (110 líneas, muy breve)
- app/Models/Pos/* (Ticket, MenuItem, MenuCategory)
- app/Repositories/Pos/* (5 repositorios sin doc)
- selemti.pos_map (40 kB), pos_sync_logs (32 kB), menu_items (24 kB)

**Gaps Críticos**:
- Documentación muy breve (110 líneas)
- 5 repositorios sin documentar
- 10 tablas sin modelo (pos_sync_logs, pos_reprocess_log, etc.)
- UI sincronización básica

**Próximos Pasos**:
1. Ampliar docs/V4.0/POS/README.md (250+ líneas)
2. Crear docs/V4.0/POS/02_SINCRONIZACION.md
3. Crear docs/V4.0/POS/03_REPOSITORIOS.md
4. Documentar 5 repositorios
5. Crear 8 modelos Eloquent faltantes

---

### 2.10 TRANSFERENCIAS (PARCIAL ⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 60% | Mencionado en Inventario | Doc dedicada faltante |
| **Código** | 75% | TransferService, models | TransferApiController huérfano |
| **BD** | 80% | transfer_cab, transfer_det, triggers | Ninguno |
| **UI** | 70% | TransferCreate.php | Flujo completo |
| **Tests** | 60% | Unit tests | Feature tests |

**Archivos Clave**:
- app/Models/Inventory/TransferHeader.php, TransferLine.php
- app/Services/Inventory/TransferService.php
- app/Http/Controllers/TransferApiController.php (huérfano, no en routes)
- app/Livewire/Transfers/Create.php
- selemti.transfer_cab (0 registros), transfer_det (0 registros)

**Gaps Críticos**:
- TransferApiController (7 endpoints) NO documentado y NO en routes
- Doc dedicada faltante
- Flujo completo no implementado (5 estados diseñados, parcialmente impl)

**Próximos Pasos**:
1. Crear docs/V4.0/Inventario/05_TRANSFERENCIAS.md
2. Documentar TransferApiController
3. Exponer API en routes/api.php
4. Completar flujo 5 estados
5. Feature tests workflow completo

---

### 2.11 FRONTEND (UI/UX) (BIEN ⭐⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 75% | 2 docs V4.0/Frontend/ | Componentes UI reutilizables |
| **Código** | 80% | Layouts, Livewire, Alpine | 87 vistas Blade huérfanas |
| **BD** | N/A | N/A | N/A |
| **UI** | 65% (6.5/10) | Bootstrap 5, responsive | 3 gaps críticos |
| **Tests** | 40% | Browser tests limitados | Cobertura UI |

**Archivos Clave**:
- docs/V4.0/Frontend/Layout.md, Componentes.md
- resources/views/layouts/terrena.blade.php (Bootstrap 5)
- resources/views/layouts/app.blade.php (Tailwind legacy)
- resources/js/app.js (Alpine, Bootstrap)
- 167 vistas Blade (80 documentadas, 87 huérfanas)

**Gaps Críticos (FASE6)**:
- Forms sin loading states (0% cobertura, 40 forms)
- Sistema notificaciones roto (70% falla)
- Delete sin confirmación (50% cobertura)
- Modales fragmentados (2 patrones)
- Layout shift permisos async
- 87 vistas Blade sin documentar

**Próximos Pasos (FASE6 - 40-50 horas)**:
1. Agregar loading states a 40 forms (4h)
2. Implementar sistema unificado toasts (6h)
3. Agregar confirmaciones delete (4h)
4. Estandarizar modales wire:ignore (12h)
5. Fix layout shift permisos (3h)
6. Documentar componentes UI (8h)

---

### 2.12 SEGURIDAD (BIEN ⭐⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 75% | Mencionado en Arquitectura | Doc independiente |
| **Código** | 80% | Spatie Permission, middleware | GUI permisos limitada |
| **BD** | 85% | users, roles, permissions, model_has_* | Ninguno |
| **UI** | 70% | Auth básico | GUI gestión permisos |
| **Tests** | 65% | Unit tests auth | Feature tests RBAC |

**Archivos Clave**:
- app/Models/User.php, UserRole.php
- Spatie Laravel Permission (roles, permisos)
- Middleware: Auth, Permission
- selemti.users (48 kB), roles (48 kB), permissions (48 kB)

**Gaps**:
- Doc independiente faltante
- GUI gestión permisos limitada
- Feature tests RBAC completos

**Próximos Pasos**:
1. Crear docs/V4.0/Seguridad/01_AUTH_PERMISOS.md
2. Crear docs/V4.0/Seguridad/02_AUDITORIA.md
3. Mejorar GUI gestión permisos
4. Feature tests RBAC

---

### 2.13 CATÁLOGOS (BIEN ⭐⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 85% | UOM completo, otros parciales | Proveedores, almacenes |
| **Código** | 90% | Livewire completos, models | Ninguno |
| **BD** | 95% | cat_unidades, cat_uom_conversion, cat_* | Tablas legacy |
| **UI** | 85% | CRUD completos | Tooltips, empty states |
| **Tests** | 70% | Feature tests | Browser tests |

**Archivos Clave**:
- docs/BD/Normalizacion/* (UOM)
- app/Livewire/Catalogs/* (UnidadesIndex, AlmacenesIndex, etc.)
- selemti.cat_unidades (88 kB), cat_uom_conversion (112 kB)

**Gaps**:
- 8 tablas legacy pendientes deprecación
- Tooltips en botones iconos
- Empty states sin gráficos

**Próximos Pasos**:
1. Plan deprecación tablas legacy
2. Agregar tooltips
3. Mejorar empty states

---

### 2.14 BASE DE DATOS (BIEN ⭐⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 75% | Migraciones, normalización UOM | Vistas, funciones críticas |
| **Código** | 90% | Migraciones completas | Modelos faltantes |
| **BD** | 90% | 147 tablas, 38 vistas, 37 funciones | 12 funciones sin doc |
| **UI** | N/A | N/A | N/A |
| **Tests** | 60% | Unit tests migraciones | Integration tests |

**Archivos Clave**:
- docs/BD/Normalizacion/* (3 docs UOM)
- docs/Migraciones/MIGRACIONES_COMPLETADAS_2025_11_05.md
- database/migrations/* (76 migraciones, 66% documentadas)
- selemti.* (147 tablas, 38 vistas, 37 funciones, 20 triggers)

**Gaps Críticos (FASE5)**:
- 12 funciones críticas sin documentar (32% cobertura)
- 82 tablas sin modelo Eloquent (56%)
- 35 tablas legacy (24%)
- 26 migraciones recientes sin doc

**Próximos Pasos (FASE5 - 48 horas)**:
1. Crear docs/V4.0/BaseDatos/01_ESQUEMA_SELEMTI.md
2. Crear docs/V4.0/BaseDatos/02_VISTAS_SISTEMA.md
3. Crear docs/V4.0/BaseDatos/03_FUNCIONES_CRITICAS.md
4. Documentar 12 funciones críticas
5. Crear 8 modelos Eloquent faltantes
6. Plan deprecación 35 tablas legacy

---

### 2.15 FINANZAS (PARCIAL ⭐⭐⭐)

| Aspecto | Estado | Evidencia | Gap |
|---------|--------|-----------|-----|
| **Documentación** | 70% | 1 doc V4.0/Finanzas/ | Cuentas por pagar detallado |
| **Código** | 65% | Mencionado en flujos | Código mínimo |
| **BD** | 70% | Tablas mencionadas | Implementación |
| **UI** | 60% | Integrado en Caja | Módulo independiente |
| **Tests** | 50% | Tests limitados | Feature tests |

**Archivos Clave**:
- docs/V4.0/Finanzas/README.md (breve)
- Integrado en módulos Caja y Reportes

**Gaps**:
- Módulo mayormente diseñado, no implementado
- Código mínimo

**Próximos Pasos**:
1. Decidir si implementar como módulo independiente
2. O mantener integrado en Caja/Reportes
3. Actualizar documentación según decisión

---

## 3. RESUMEN DE GAPS CRÍTICOS

### 3.1 Top 10 Gaps por Impacto

| # | Gap | Módulos | Impacto | Esfuerzo |
|---|-----|---------|---------|----------|
| 1 | Forms sin loading states | Frontend (40 forms) | CRÍTICO | 4h |
| 2 | Notificaciones rotas | Frontend (3 patrones) | CRÍTICO | 6h |
| 3 | PosConsumptionService triplicado | Ventas | CRÍTICO | 4h |
| 4 | Funciones BD sin doc | BD (12 funciones) | CRÍTICO | 20h |
| 5 | ProductionService duplicado | Producción | ALTO | 3h |
| 6 | Código huérfano | Todos (189 archivos) | ALTO | 116h |
| 7 | Delete sin confirmación | Frontend (15 componentes) | ALTO | 4h |
| 8 | Tablas sin modelo | BD (82 tablas) | ALTO | 16h |
| 9 | Tablas legacy | BD (35 tablas) | MEDIO | 12h |
| 10 | Modales fragmentados | Frontend (15 modales) | MEDIO | 12h |

### 3.2 Esfuerzo Total Estimado

| Categoría | Horas | Prioridad |
|-----------|-------|-----------|
| UI/UX Crítico (FASE6) | 40-50 | 🔴 CRÍTICA |
| Código Huérfano (FASE4) | 116 | 🔴 CRÍTICA |
| BD Funciones/Modelos (FASE5) | 48 | 🟡 ALTA |
| Documentación (FASE2) | 48 | 🟡 ALTA |
| **TOTAL** | **252-262** | **~6-7 semanas** |

---

## 4. ROADMAP DE PRIORIZACIÓN

### Sprint 1 (2 semanas) - Gaps Críticos UI/UX
1. Forms loading states (4h)
2. Sistema toasts unificado (6h)
3. Confirmaciones delete (4h)
4. Consolidar PosConsumptionService (4h)
5. Consolidar ProductionService (3h)
6. Fix layout shift permisos (3h)
**Total**: 24h

### Sprint 2 (2 semanas) - Funciones BD Críticas
1. Documentar fn_recipe_cost_at() (3h)
2. Documentar fn_recipes_using_item() (3h)
3. Documentar fn_item_unit_cost_at() (3h)
4. Documentar fn_expandir_consumo_ticket() (3h)
5. Documentar recalcular_costos_periodo() (3h)
6. Crear 8 modelos Eloquent (16h)
**Total**: 31h

### Sprint 3-4 (4 semanas) - Documentación Core
1. Ampliar docs Recetas (8h)
2. Ampliar docs Producción (8h)
3. Ampliar docs POS (8h)
4. Crear docs Ventas (8h)
5. Crear docs BaseDatos (12h)
6. Crear docs Seguridad (8h)
**Total**: 52h

### Sprint 5-6 (4 semanas) - Código Huérfano Prioritario
1. Documentar 19 servicios (38h)
2. Documentar 20 modelos (20h)
3. Documentar 18 Livewire (18h)
4. Documentar 19 controladores (19h)
**Total**: 95h

### Sprint 7-8 (4 semanas) - Pulido y Tests
1. Estandarizar modales (12h)
2. Mejorar empty states (3h)
3. Plan deprecación legacy (12h)
4. Tests cobertura +40% (60h)
**Total**: 87h

---

**FIN MATRIZ ALINEACIÓN v2 - CLAUDE**
