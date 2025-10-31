# 馃幆 PLAN MAESTRO UI/UX ENTERPRISE - TerrenaLaravel

**Proyecto**: TerrenaLaravel - Sistema ERP Restaurantes  
**Versi贸n**: v7.0 Enterprise (Post-Normalizaci贸n BD)  
**Fecha**: 31 de octubre de 2025  
**Estado**: 馃煝 READY TO EXECUTE

---

## 馃搵 TABLA DE CONTENIDOS

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Estado Actual](#estado-actual)
3. [Arquitectura y Stack](#arquitectura-y-stack)
4. [Sistema de Permisos](#sistema-de-permisos)
5. [Roadmap de Implementaci贸n](#roadmap-de-implementaci贸n)
6. [An谩lisis por M贸dulo](#an谩lisis-por-m贸dulo)
7. [Quick Wins](#quick-wins)
8. [M茅tricas y KPIs](#m茅tricas-y-kpis)
9. [Plan de Testing](#plan-de-testing)
10. [Entregables](#entregables)

---

## 1. RESUMEN EJECUTIVO

### 馃帀 Logro Mayor: Base de Datos Enterprise Completada

**Acabamos de completar** (31 octubre 2025, 00:40):
- 鉁?**5 Fases de normalizaci贸n** (Fundamentos 鈫?Consolidaci贸n 鈫?Integridad 鈫?Performance 鈫?Enterprise)
- 鉁?**141 tablas** enterprise-grade
- 鉁?**127 Foreign Keys** verificadas
- 鉁?**415 铆ndices** optimizados
- 鉁?**20 triggers** de auditor铆a
- 鉁?**51 vistas** de compatibilidad
- 鉁?**4 vistas materializadas** para reportes
- 鉁?**Audit log global** implementado
- 鉁?**Zero breaking changes** + c贸digo legacy compatible

### 馃幆 Objetivo del Plan UI/UX

Transformar el frontend de un sistema funcional a un **ERP comercial de clase mundial** aprovechando la base de datos enterprise que acabamos de crear.

### 馃搳 Estado Actual vs Objetivo

| M贸dulo | Estado Actual | Objetivo | Gap |
|--------|---------------|----------|-----|
| **Inventario** | 60-70% | 95% | UI moderna + validaciones |
| **Compras/Replenishment** | 40-50% | 95% | Motor + pol铆ticas |
| **Recetas/Costos** | 50-60% | 95% | Versionado + snapshots |
| **Producci贸n** | 30-40% | 90% | UI operativa completa |
| **POS Integration** | 70% | 95% | Auditor铆a + mapeos |
| **Reportes** | 30-40% | 90% | Exports + drill-down |
| **Permisos** | 80% | 98% | Matriz + gating |
| **Caja Chica** | 70% | 90% | Reglas + checklist |

### 馃殌 Ventaja Competitiva

Con la BD enterprise completada, tenemos:
1. 鉁?**Integridad garantizada** por constraints de BD
2. 鉁?**Auditor铆a autom谩tica** v铆a triggers
3. 鉁?**Performance optimizada** con 415 铆ndices
4. 鉁?**Escalabilidad** probada (vistas materializadas)
5. 鉁?**C贸digo legacy compatible** (vistas v_*)

**Esto significa**: El frontend puede ser **m谩s simple y r谩pido** porque la BD hace el trabajo pesado.

---

## 2. ESTADO ACTUAL

### 2.1 Stack Tecnol贸gico Actual

```
Backend:
鈹溾攢鈹€ Laravel 10.x
鈹溾攢鈹€ PHP 8.2+
鈹溾攢鈹€ PostgreSQL 9.5
鈹斺攢鈹€ Spatie Permissions (roles/permisos)

Frontend:
鈹溾攢鈹€ Blade Templates
鈹溾攢鈹€ Alpine.js (interactividad)
鈹溾攢鈹€ Tailwind CSS 3.x
鈹溾攢鈹€ Bootstrap 5 (legacy, migrar gradualmente)
鈹斺攢鈹€ Livewire (componentes reactivos)

Infraestructura:
鈹溾攢鈹€ XAMPP (desarrollo)
鈹溾攢鈹€ Git (control de versiones)
鈹斺攢鈹€ Artisan (CLI)
```

### 2.2 M贸dulos Existentes

**Inventario**:
- 鉁?Items/Altas: Filtro + alta b谩sica
- 鉁?Recepciones: Modal completo con FEFO
- 鉁?Lotes/Caducidades: Tableros vac铆os
- 鉁?Conteos: Estados + tablero
- 鉁?Transferencias: Borrador/Despachada

**Compras**:
- 鉁?Solicitudes/脫rdenes: Estructura completa
- 鈿狅笍 Pedidos Sugeridos: UI lista, motor falta
- 鈿狅笍 Pol铆ticas de Stock: UI pendiente

**Recetas**:
- 鉁?Listado con precios
- 鉁?Editor b谩sico (ID, PLU, ingredientes)
- 鈿狅笍 Alertas de costo vac铆o
- 鉂?Versionado: No implementado
- 鉂?Snapshots autom谩ticos: Falta

**Producci贸n**:
- 鉁?API completa (plan/consume/complete/post)
- 鉂?UI operativa: No existe

**POS**:
- 鉁?Mapeos: Vista b谩sica
- 鈿狅笍 Auditor铆a: Queries v6 listas, UI falta
- 鉁?Integraci贸n read-only desde `public.*`

**Caja Chica**:
- 鉁?Precorte por denominaciones
- 鉁?Panel de excepciones
- 鈿狅笍 Reglas parametrizables: Falta

**Reportes**:
- 鉁?Dashboard principal con KPIs ventas
- 鉂?Exports CSV/PDF: No
- 鉂?Drill-down: No
- 鉂?Reportes programados: No

**Cat谩logos**:
- 鉁?Sucursales, Almacenes: Completo
- 鉁?Unidades/Conversiones: Muy bien
- 鉁?Proveedores: B谩sico
- 鈿狅笍 Pol铆ticas de Stock: UI pendiente

**Permisos**:
- 鉁?45 permisos definidos
- 鉁?9 m贸dulos
- 鉁?7 roles base
- 鈿狅笍 Matriz visual: Falta
- 鈿狅笍 Auditor铆a de cambios: Falta

### 2.3 Fortalezas Actuales

1. 鉁?**Base de Datos Enterprise** (reci茅n completada)
2. 鉁?**Estructura Laravel s贸lida**
3. 鉁?**Spatie Permissions** implementado
4. 鉁?**Alpine.js + Livewire** (moderno, r谩pido)
5. 鉁?**Tailwind CSS** (dise帽o consistente)
6. 鉁?**API REST** bien estructurada
7. 鉁?**Integraci贸n POS** read-only funcional

### 2.4 Gaps Cr铆ticos Identificados

| Prioridad | Gap | Impacto Negocio | Esfuerzo |
|-----------|-----|-----------------|----------|
| 馃敟 **CR脥TICO** | Motor de Replenishment | ALTO | MEDIO |
| 馃敟 **CR脥TICO** | Snapshot de Costos (auto) | ALTO | BAJO |
| 馃敟 **CR脥TICO** | Validaciones inline | MEDIO | BAJO |
| 鈿狅笍 **ALTO** | Versionado de Recetas | ALTO | MEDIO |
| 鈿狅笍 **ALTO** | Export Reportes | MEDIO | BAJO |
| 鈿狅笍 **ALTO** | UI Producci贸n | MEDIO | ALTO |
| 鈿狅笍 **MEDIO** | Pol铆ticas de Stock UI | ALTO | MEDIO |
| 鈿狅笍 **MEDIO** | Auditor铆a POS UI | MEDIO | BAJO |
| 馃煝 **BAJO** | Mobile conteos | BAJO | MEDIO |
| 馃煝 **BAJO** | OCR lotes | BAJO | ALTO |

---

## 3. ARQUITECTURA Y STACK

### 3.1 Arquitectura Propuesta (Layers)

```
鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?
鈹?                   PRESENTATION                      鈹?
鈹? Blade + Alpine.js + Livewire + Tailwind CSS       鈹?
鈹? 鈥?Validaci贸n inline (Alpine)                       鈹?
鈹? 鈥?Componentes reactivos (Livewire)                 鈹?
鈹? 鈥?UI consistente (Tailwind)                        鈹?
鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?
                         鈫?
鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?
鈹?                  APPLICATION                        鈹?
鈹? Controllers (HTTP) + Livewire Components           鈹?
鈹? 鈥?Routing                                          鈹?
鈹? 鈥?Request validation                               鈹?
鈹? 鈥?Response formatting                              鈹?
鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?
                         鈫?
鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?
鈹?                    BUSINESS                         鈹?
鈹? Services (l贸gica de negocio)                       鈹?
鈹? 鈹溾攢鈹€ ItemService                                    鈹?
鈹? 鈹溾攢鈹€ CostingService                                 鈹?
鈹? 鈹溾攢鈹€ ReplenishmentEngine 猸?                        鈹?
鈹? 鈹溾攢鈹€ RecipeService                                  鈹?
鈹? 鈹溾攢鈹€ ProductionService                              鈹?
鈹? 鈹溾攢鈹€ TransferService                                鈹?
鈹? 鈹斺攢鈹€ ReportingService                               鈹?
鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?
                         鈫?
鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?
鈹?                    DATA ACCESS                      鈹?
鈹? Models (Eloquent ORM)                              鈹?
鈹? 鈥?Relationships                                    鈹?
鈹? 鈥?Scopes                                           鈹?
鈹? 鈥?Accessors/Mutators                               鈹?
鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?
                         鈫?
鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?
鈹?                   DATABASE 鉁?                      鈹?
鈹? PostgreSQL 9.5 - ENTERPRISE GRADE                  鈹?
鈹? 鈥?141 tablas                                       鈹?
鈹? 鈥?127 FKs                                          鈹?
鈹? 鈥?415 铆ndices                                      鈹?
鈹? 鈥?20 triggers                                      鈹?
鈹? 鈥?Audit log global                                 鈹?
鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?
```

### 3.2 Patrones de Dise帽o

**1. Repository Pattern** (opcional, para queries complejas):
```php
app/Repositories/
鈹溾攢鈹€ ItemRepository
鈹溾攢鈹€ RecipeRepository
鈹斺攢鈹€ ReportRepository
```

**2. Service Layer Pattern** (obligatorio):
```php
app/Services/
鈹溾攢鈹€ Inventory/
鈹?  鈹溾攢鈹€ ItemService.php
鈹?  鈹溾攢鈹€ ReceptionService.php
鈹?  鈹斺攢鈹€ TransferService.php
鈹溾攢鈹€ Purchasing/
鈹?  鈹溾攢鈹€ ReplenishmentEngine.php 猸?
鈹?  鈹斺攢鈹€ OrderService.php
鈹溾攢鈹€ Recipes/
鈹?  鈹溾攢鈹€ RecipeService.php
鈹?  鈹斺攢鈹€ CostingService.php 猸?
鈹斺攢鈹€ Production/
    鈹斺攢鈹€ ProductionService.php
```

**3. Job/Queue Pattern** (as铆ncrono):
```php
app/Jobs/
鈹溾攢鈹€ RecalculateRecipeCosts.php 猸?
鈹溾攢鈹€ GenerateReplenishmentSuggestions.php 猸?
鈹溾攢鈹€ UpdateCostSnapshots.php
鈹溾攢鈹€ ProcessPosConsumption.php
鈹斺攢鈹€ GenerateReports.php
```

**4. Event/Listener Pattern** (auditor铆a):
```php
app/Events/
鈹溾攢鈹€ ItemCreated.php
鈹溾攢鈹€ CostChanged.php
鈹溾攢鈹€ RecipeUpdated.php
鈹斺攢鈹€ StockBelowMinimum.php

app/Listeners/
鈹溾攢鈹€ LogItemCreation.php
鈹溾攢鈹€ RecalculateRecipeCosts.php
鈹溾攢鈹€ NotifyStockAlert.php
鈹斺攢鈹€ UpdateCostSnapshot.php
```

### 3.3 Estructura de Directorios Propuesta

```
app/
鈹溾攢鈹€ Http/
鈹?  鈹溾攢鈹€ Controllers/          (delgados, solo routing)
鈹?  鈹?  鈹溾攢鈹€ InventoryController.php
鈹?  鈹?  鈹溾攢鈹€ PurchasingController.php
鈹?  鈹?  鈹溾攢鈹€ RecipeController.php
鈹?  鈹?  鈹斺攢鈹€ ProductionController.php
鈹?  鈹溾攢鈹€ Livewire/            (componentes reactivos)
鈹?  鈹?  鈹溾攢鈹€ Inventory/
鈹?  鈹?  鈹?  鈹溾攢鈹€ ItemForm.php
鈹?  鈹?  鈹?  鈹溾攢鈹€ ItemList.php
鈹?  鈹?  鈹?  鈹溾攢鈹€ ReceptionForm.php
鈹?  鈹?  鈹?  鈹斺攢鈹€ CountingForm.php
鈹?  鈹?  鈹溾攢鈹€ Purchasing/
鈹?  鈹?  鈹?  鈹溾攢鈹€ SuggestedOrders.php 猸?
鈹?  鈹?  鈹?  鈹斺攢鈹€ StockPolicies.php
鈹?  鈹?  鈹斺攢鈹€ Recipes/
鈹?  鈹?      鈹溾攢鈹€ RecipeEditor.php
鈹?  鈹?      鈹斺攢鈹€ CostAlert.php
鈹?  鈹溾攢鈹€ Middleware/
鈹?  鈹?  鈹溾攢鈹€ CheckPermission.php 猸?
鈹?  鈹?  鈹斺攢鈹€ AuditLog.php
鈹?  鈹斺攢鈹€ Requests/            (validaci贸n)
鈹?      鈹溾攢鈹€ StoreItemRequest.php
鈹?      鈹斺攢鈹€ PostReceptionRequest.php
鈹溾攢鈹€ Services/                (l贸gica de negocio) 猸?
鈹溾攢鈹€ Jobs/                    (procesamiento as铆ncrono) 猸?
鈹溾攢鈹€ Events/                  (eventos del sistema)
鈹溾攢鈹€ Listeners/               (respuestas a eventos)
鈹溾攢鈹€ Models/                  (Eloquent ORM)
鈹?  鈹溾攢鈹€ Item.php
鈹?  鈹溾攢鈹€ InventoryBatch.php
鈹?  鈹溾攢鈹€ Recipe.php
鈹?  鈹溾攢鈹€ RecipeVersion.php 猸?
鈹?  鈹斺攢鈹€ StockPolicy.php 猸?
鈹斺攢鈹€ Policies/                (autorizaci贸n) 猸?
    鈹溾攢鈹€ InventoryPolicy.php
    鈹溾攢鈹€ PurchasingPolicy.php
    鈹溾攢鈹€ RecipePolicy.php
    鈹斺攢鈹€ ProductionPolicy.php

resources/
鈹溾攢鈹€ views/
鈹?  鈹溾攢鈹€ components/          (Blade components reusables) 猸?
鈹?  鈹?  鈹溾攢鈹€ forms/
鈹?  鈹?  鈹?  鈹溾攢鈹€ input.blade.php
鈹?  鈹?  鈹?  鈹溾攢鈹€ select.blade.php
鈹?  鈹?  鈹?  鈹斺攢鈹€ datepicker.blade.php
鈹?  鈹?  鈹溾攢鈹€ ui/
鈹?  鈹?  鈹?  鈹溾攢鈹€ toast.blade.php 猸?
鈹?  鈹?  鈹?  鈹溾攢鈹€ modal.blade.php
鈹?  鈹?  鈹?  鈹溾攢鈹€ card.blade.php
鈹?  鈹?  鈹?  鈹溾攢鈹€ empty-state.blade.php 猸?
鈹?  鈹?  鈹?  鈹斺攢鈹€ loading-skeleton.blade.php 猸?
鈹?  鈹?  鈹斺攢鈹€ tables/
鈹?  鈹?      鈹溾攢鈹€ table.blade.php
鈹?  鈹?      鈹斺攢鈹€ pagination.blade.php
鈹?  鈹溾攢鈹€ livewire/            (vistas Livewire)
鈹?  鈹溾攢鈹€ inventory/
鈹?  鈹溾攢鈹€ purchasing/
鈹?  鈹溾攢鈹€ recipes/
鈹?  鈹斺攢鈹€ layouts/
鈹?      鈹溾攢鈹€ app.blade.php
鈹?      鈹溾攢鈹€ guest.blade.php
鈹?      鈹斺攢鈹€ components/
鈹?          鈹溾攢鈹€ navbar.blade.php
鈹?          鈹溾攢鈹€ sidebar.blade.php 猸?
鈹?          鈹斺攢鈹€ breadcrumb.blade.php
鈹斺攢鈹€ js/
    鈹溾攢鈹€ alpine/              (Alpine.js components)
    鈹?  鈹溾攢鈹€ validation.js 猸?
    鈹?  鈹溾攢鈹€ search.js
    鈹?  鈹斺攢鈹€ modals.js
    鈹斺攢鈹€ app.js

database/
鈹溾攢鈹€ migrations/              (nuevas tablas)
鈹?  鈹溾攢鈹€ 2025_11_01_create_stock_policies_table.php 猸?
鈹?  鈹溾攢鈹€ 2025_11_01_create_replenishment_runs_table.php 猸?
鈹?  鈹溾攢鈹€ 2025_11_01_create_recipe_versions_table.php 猸?
鈹?  鈹溾攢鈹€ 2025_11_01_create_recipe_cost_snapshots_table.php 猸?
鈹?  鈹斺攢鈹€ 2025_11_01_create_production_batches_table.php
鈹斺攢鈹€ seeders/
    鈹溾攢鈹€ PermissionsSeederV6.php 猸?
    鈹斺攢鈹€ StockPoliciesSeeder.php
```

---

## 4. SISTEMA DE PERMISOS

### 4.1 Arquitectura de Permisos (Spatie)

**Jerarqu铆a**:
```
Usuario
  鈫?
Roles (plantillas)
  鈫?
Permisos (at贸micos)
  鈫?
Gates (autorizaci贸n)
  鈫?
UI Gating (mostrar/ocultar)
```

### 4.2 Permisos At贸micos (44 permisos)

#### **Inventario** (14 permisos)
```
inventory.items.view              鈫?Ver cat谩logo de 铆tems
inventory.items.manage            鈫?Crear/Editar 铆tems
inventory.uoms.view               鈫?Ver presentaciones
inventory.uoms.manage             鈫?Gestionar presentaciones
inventory.uoms.convert.manage     鈫?Gestionar conversiones
inventory.receptions.view         鈫?Ver recepciones
inventory.receptions.post         鈫?Postear recepciones (mov_inv)
inventory.counts.view             鈫?Ver conteos
inventory.counts.open             鈫?Abrir conteo
inventory.counts.close            鈫?Cerrar conteo (valida v6)
inventory.moves.view              鈫?Ver movimientos
inventory.moves.adjust            鈫?Ajuste manual
inventory.snapshot.generate       鈫?Generar snapshot diario
inventory.snapshot.view           鈫?Ver snapshots
```

#### **Compras** (3 permisos)
```
purchasing.suggested.view         鈫?Ver pedidos sugeridos
purchasing.orders.manage          鈫?Crear/Editar 贸rdenes
purchasing.orders.approve         鈫?Aprobar 贸rdenes
```

#### **Recetas/Costos** (4 permisos)
```
recipes.view                      鈫?Ver recetas
recipes.manage                    鈫?Crear/Editar recetas
recipes.costs.recalc.schedule     鈫?Cron recalcular costos (01:10)
recipes.costs.snapshot            鈫?Snapshot manual de costo
```

#### **POS** (4 permisos)
```
pos.map.view                      鈫?Ver mapeos POS
pos.map.manage                    鈫?Gestionar mapeos
pos.audit.run                     鈫?Ejecutar auditor铆a SQL v6
pos.reprocess.run                 鈫?Reprocesar tickets
```

#### **Producci贸n** (2 permisos)
```
production.orders.view            鈫?Ver 贸rdenes de producci贸n
production.orders.close           鈫?Cerrar OP (consume MP)
```

#### **Caja** (2 permisos)
```
cashier.preclose.run              鈫?Ejecutar precorte
cashier.close.run                 鈫?Corte final
```

#### **Reportes** (2 permisos)
```
reports.kpis.view                 鈫?Ver KPIs/dashboard
reports.audit.view                鈫?Ver auditor铆a
```

#### **Sistema** (3 permisos)
```
system.users.view                 鈫?Ver usuarios
system.templates.manage           鈫?Gestionar plantillas de roles
system.permissions.direct.manage  鈫?Asignar permisos especiales
```

### 4.3 Plantillas de Roles (7 roles predefinidos)

**1. Almacenista** (6 permisos):
```
鉁?inventory.items.view
鉁?inventory.counts.view
鉁?inventory.counts.open
鉁?inventory.counts.close
鉁?inventory.moves.view
鉁?inventory.snapshot.view
```

**Caso de uso**: Operador de almac茅n que realiza conteos f铆sicos.

---

**2. Jefe de Almac茅n** (9 permisos):
```
鉁?inventory.items.view
鉁?inventory.counts.view
鉁?inventory.counts.open
鉁?inventory.counts.close
鉁?inventory.moves.view
鉁?inventory.moves.adjust          鈫?Ajustes manuales
鉁?inventory.receptions.view
鉁?inventory.receptions.post       鈫?Posteo de recepciones
鉁?pos.map.view
```

**Caso de uso**: Supervisor de almac茅n con capacidad de ajustar inventario.

---

**3. Compras** (4 permisos):
```
鉁?purchasing.suggested.view
鉁?purchasing.orders.manage
鉁?purchasing.orders.approve       鈫?Autorizaci贸n de compras
鉁?inventory.receptions.view
```

**Caso de uso**: Departamento de compras, manejo de pedidos y proveedores.

---

**4. Costos / Recetas** (5 permisos):
```
鉁?recipes.view
鉁?recipes.manage
鉁?recipes.costs.recalc.schedule   鈫?Cron autom谩tico
鉁?recipes.costs.snapshot          鈫?Snapshot manual
鉁?pos.map.manage                  鈫?Mapeo men煤
```

**Caso de uso**: Chef o gerente de costos que gestiona recetas y precios.

---

**5. Producci贸n** (3 permisos):
```
鉁?production.orders.view
鉁?production.orders.close         鈫?Cierre de OP
鉁?inventory.items.view
```

**Caso de uso**: Operador de producci贸n (si aplica en el negocio).

---

**6. Auditor铆a / Reportes** (4 permisos):
```
鉁?reports.kpis.view
鉁?reports.audit.view
鉁?pos.audit.run                   鈫?Auditor铆a SQL v6
鉁?inventory.snapshot.view
```

**Caso de uso**: Contador o gerente general que revisa reportes.

---

**7. Administrador del Sistema** (wildcard):
```
鉁?* (todos los permisos)
```

**Caso de uso**: IT o due帽o con acceso total.

---

### 4.4 UI Gating Map (visibilidad por permiso)

#### **Inventario**
| Ruta/Elemento | Permiso Requerido | Tipo |
|---------------|-------------------|------|
| `/inventario/items` | `inventory.items.view` | Vista |
| 鈫?Bot贸n "Nuevo 脥tem" | `inventory.items.manage` | Acci贸n |
| 鈫?Acci贸n "Editar" | `inventory.items.manage` | Acci贸n |
| 鈫?Acci贸n "Ajuste manual" | `inventory.moves.adjust` | Acci贸n |
| `/inventario/recepciones` | `inventory.receptions.view` | Vista |
| 鈫?Bot贸n "Postear" | `inventory.receptions.post` | Acci贸n |
| `/inventario/conteos` | `inventory.counts.view` | Vista |
| 鈫?Bot贸n "Abrir conteo" | `inventory.counts.open` | Acci贸n |
| 鈫?Bot贸n "Cerrar conteo" | `inventory.counts.close` | Acci贸n |
| `/inventario/snapshot` | `inventory.snapshot.view` | Vista |
| 鈫?Bot贸n "Generar snapshot" | `inventory.snapshot.generate` | Acci贸n |

#### **POS**
| Ruta/Elemento | Permiso Requerido | Tipo |
|---------------|-------------------|------|
| `/pos/map` | `pos.map.view` | Vista |
| 鈫?Bot贸n "Nuevo mapeo" | `pos.map.manage` | Acci贸n |
| 鈫?Acci贸n "Editar mapeo" | `pos.map.manage` | Acci贸n |
| `/pos/auditoria` | `pos.audit.run` | Vista + Acci贸n |
| 鈫?Bot贸n "Ejecutar auditor铆a SQL v6" | `pos.audit.run` | Acci贸n |

#### **Recetas / Costos**
| Ruta/Elemento | Permiso Requerido | Tipo |
|---------------|-------------------|------|
| `/recetas` | `recipes.view` | Vista |
| 鈫?Bot贸n "Nueva receta" | `recipes.manage` | Acci贸n |
| 鈫?Acci贸n "Snapshot costo" | `recipes.costs.snapshot` | Acci贸n |

#### **Compras**
| Ruta/Elemento | Permiso Requerido | Tipo |
|---------------|-------------------|------|
| `/compras/sugerido` | `purchasing.suggested.view` | Vista |
| `/compras/ordenes` | `purchasing.orders.manage` | Vista |
| 鈫?Bot贸n "Nueva orden" | `purchasing.orders.manage` | Acci贸n |
| 鈫?Bot贸n "Aprobar" | `purchasing.orders.approve` | Acci贸n |

#### **Producci贸n**
| Ruta/Elemento | Permiso Requerido | Tipo |
|---------------|-------------------|------|
| `/produccion/ordenes` | `production.orders.view` | Vista |
| 鈫?Bot贸n "Cerrar OP" | `production.orders.close` | Acci贸n |

#### **Reportes**
| Ruta/Elemento | Permiso Requerido | Tipo |
|---------------|-------------------|------|
| `/reportes/kpis` | `reports.kpis.view` | Vista |
| `/reportes/auditoria` | `reports.audit.view` | Vista |

#### **Sistema**
| Ruta/Elemento | Permiso Requerido | Tipo |
|---------------|-------------------|------|
| `/sistema/usuarios` | `system.users.view` | Vista |
| `/sistema/plantillas` | `system.templates.manage` | Vista + CRUD |
| `/sistema/usuarios/{id}/permisos` | `system.permissions.direct.manage` | Vista + Asignar |

### 4.5 Implementaci贸n en C贸digo

**Middleware (route-level)**:
```php
// routes/web.php
Route::middleware(['auth', 'permission:inventory.items.view'])
    ->group(function () {
        Route::get('/inventario/items', [InventoryController::class, 'items']);
    });
```

**Blade (UI-level)**:
```blade
{{-- resources/views/inventory/items.blade.php --}}
@can('inventory.items.manage')
    <button wire:click="createItem">Nuevo 脥tem</button>
@endcan

@cannot('inventory.items.manage')
    {{-- Mostrar mensaje o nada --}}
@endcannot
```

**Livewire (component-level)**:
```php
// app/Http/Livewire/Inventory/ItemList.php
public function createItem()
{
    if (!Gate::allows('inventory.items.manage')) {
        abort(403, 'No tienes permiso para crear 铆tems.');
    }
    
    // L贸gica...
}
```

**Policy (model-level)**:
```php
// app/Policies/InventoryPolicy.php
class InventoryPolicy
{
    public function viewItems(User $user): bool
    {
        return $user->hasPermissionTo('inventory.items.view');
    }
    
    public function manageItems(User $user): bool
    {
        return $user->hasPermissionTo('inventory.items.manage');
    }
}
```

---

## 5. ROADMAP DE IMPLEMENTACI脫N

### 5.1 Visi贸n General (6 meses)

```
Mes 1: Sprint 0 + Sprint 1 (Inventario Base)
Mes 2: Sprint 2 (Replenishment 馃敟) + Sprint 2.5 (Reportes)
Mes 3: Sprint 3 (Recepciones Avanzadas) + Sprint 4 (Recetas)
Mes 4: Sprint 5 (Transferencias) + Sprint 6 (Producci贸n)
Mes 5: Sprint 7 (Mobile) + Optimizaciones
Mes 6: Testing QA + Capacitaci贸n + Go-Live
```

### 5.2 Sprints Detallados

---

#### **SPRINT 0: Foundation** (1-2 semanas)
**Objetivo**: Crear base s贸lida de componentes y design system

**Tareas**:
1. 鉁?**Design System** (5 d铆as)
   - [ ] Tailwind config personalizado
   - [ ] Paleta de colores consistente
   - [ ] Tipograf铆a y espaciado
   - [ ] Componentes base:
     - [ ] `<x-button>`
     - [ ] `<x-input>`
     - [ ] `<x-select>`
     - [ ] `<x-textarea>`
     - [ ] `<x-datepicker>`
     - [ ] `<x-modal>`
     - [ ] `<x-toast>` 猸?
     - [ ] `<x-card>`
     - [ ] `<x-table>`
     - [ ] `<x-empty-state>` 猸?
     - [ ] `<x-loading-skeleton>` 猸?

2. 鉁?**Sistema de Validaci贸n Unificado** (3 d铆as)
   - [ ] Validaci贸n inline con Alpine.js 猸?
   - [ ] Mensajes de error consistentes
   - [ ] Highlight de campos con error
   - [ ] Tooltips de ayuda

3. 鉁?**Sistema de Notificaciones** (2 d铆as)
   - [ ] Toast notifications (茅xito/error/warning/info)
   - [ ] Alpine.js store para toasts
   - [ ] Auto-dismiss configurable

4. 鉁?**Auditor铆a Base** (2 d铆as)
   - [ ] Middleware de auditor铆a
   - [ ] Log de errores estructurado
   - [ ] Eventos CRUD b谩sicos

**Entregables**:
- 鉁?Gu铆a de dise帽o (Figma/PDF)
- 鉁?Storybook de componentes
- 鉁?Sistema de validaci贸n funcionando
- 鉁?PR: `feat/design-system-v7`

**Criterios de Aceptaci贸n**:
- [ ] Todos los componentes funcionan en producci贸n
- [ ] Gu铆a documentada con ejemplos
- [ ] Tests unitarios de componentes cr铆ticos

---

#### **SPRINT 1: Inventario Base + Costos** (2 semanas)
**Objetivo**: Inventario s贸lido con costos actualizados

**Tareas**:

1. 鉁?**Alta de 脥tems (Wizard 2 Pasos)** (5 d铆as)
   - [ ] Paso 1: Datos maestros (nombre, categor铆a, UOM base)
   - [ ] Paso 2: Presentaciones/Proveedor (opcional)
   - [ ] Validaci贸n inline por campo 猸?
   - [ ] Preview de c贸digo CAT-SUB-##### antes de guardar
   - [ ] Bot贸n "Crear y seguir con presentaciones"
   - [ ] Auto-sugerencias de nombres normalizados

2. 鉁?**Proveedor-Insumo (Presentaciones)** (3 d铆as)
   - [ ] CRUD completo
   - [ ] Plantilla r谩pida desde recepci贸n
   - [ ] Auto-conversi贸n UOM base 鈫?compra
   - [ ] Tooltip mostrando factor de conversi贸n

3. 鉁?**Recepciones Posteables** (5 d铆as)
   - [ ] Estados: Pre-validada 鈫?Aprobada 鈫?Posteada
   - [ ] Snapshot de costo al postear 猸?
   - [ ] Adjuntos m煤ltiples (drag & drop)
   - [ ] Tolerancias de qty (alerta si discrepancia > X%)
   - [ ] Genera `mov_inv` autom谩ticamente

4. 鉁?**UOM Assistant** (2 d铆as)
   - [ ] Creaci贸n inversa autom谩tica (si creo kg鈫抔, crear g鈫択g)
   - [ ] Validaci贸n de circularidad
   - [ ] Preview de conversi贸n

**Modelo de Datos Necesario**:
```sql
-- Ya existe en BD:
鉁?selemti.items
鉁?selemti.inventory_batch

-- A帽adir:
CREATE TABLE selemti.vendor_pricelist (
    id BIGSERIAL PRIMARY KEY,
    proveedor_id BIGINT REFERENCES selemti.proveedores(id),
    item_id VARCHAR(20) REFERENCES selemti.items(id),
    uom_compra VARCHAR(10),
    pack_size NUMERIC(10,3),
    costo NUMERIC(15,4),
    vigencia_desde DATE,
    vigencia_hasta DATE,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE selemti.cost_snapshot (
    id BIGSERIAL PRIMARY KEY,
    item_id VARCHAR(20) REFERENCES selemti.items(id),
    costo_base NUMERIC(15,4),
    origen VARCHAR(20), -- 'RECEPCION', 'AJUSTE', 'CALCULADO'
    referencia_id BIGINT, -- ID de recepcion o ajuste
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE selemti.insumo_alias (
    id BIGSERIAL PRIMARY KEY,
    item_id VARCHAR(20) REFERENCES selemti.items(id),
    alias VARCHAR(200),
    search_vector tsvector,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Entregables**:
- 鉁?Wizard de 铆tems funcionando
- 鉁?Recepciones con snapshot de costo
- 鉁?UOM con conversiones autom谩ticas
- 鉁?PR: `feat/inventory-base-v7`

**Criterios de Aceptaci贸n**:
- [ ] Usuario puede crear 铆tem 鈫?a帽adir presentaci贸n 鈫?recepcionar con conversi贸n autom谩tica 鈫?ver lote/caducidad 鈫?costo base actualizado
- [ ] Tests de integraci贸n pasando
- [ ] Validaciones inline funcionando

---

#### **SPRINT 2: Replenishment + Pol铆ticas** 馃敟 (2-3 semanas)
**Objetivo**: Motor de sugerencias de pedidos (coraz贸n del negocio)

**Tareas**:

1. 鉁?**UI de Pol铆ticas de Stock** (3 d铆as)
   - [ ] CRUD por 铆tem/sucursal
   - [ ] Campos:
     - [ ] Stock m铆nimo
     - [ ] Stock m谩ximo
     - [ ] Safety stock
     - [ ] Lead time (d铆as)
     - [ ] M茅todo de replenishment (dropdown)
   - [ ] Bulk import CSV
   - [ ] Export template

2. 鉁?**Motor de Replenishment** (7 d铆as) 猸愨瓙猸?
   - [ ] M茅todo 1: Min-Max b谩sico
     ```
     Si stock_actual < min:
         sugerido = max - stock_actual
     ```
   - [ ] M茅todo 2: Simple Moving Average (SMA)
     ```
     consumo_promedio = SUM(consumo_煤ltimos_n_d铆as) / n
     sugerido = (consumo_promedio * lead_time) + safety_stock - stock_actual
     ```
   - [ ] M茅todo 3: Consumo POS (煤ltimos n d铆as)
     ```
     Leer de inv_consumo_pos_det agrupado
     sugerido = proyecci贸n basada en consumo
     ```
   - [ ] Integraci贸n con POS (read-only desde `public.*`)
   - [ ] Validaci贸n: considerar 贸rdenes pendientes
   - [ ] C谩lculo de cobertura (d铆as)

3. 鉁?**UI de Pedidos Sugeridos** (4 d铆as)
   - [ ] Bot贸n "Generar Sugerencias"
   - [ ] Grilla editable con:
     - [ ] 脥tem
     - [ ] Stock actual
     - [ ] Stock min/max
     - [ ] Consumo promedio
     - [ ] Qty sugerida (editable)
     - [ ] Cobertura (d铆as)
     - [ ] Raz贸n del c谩lculo (tooltip) 猸?
   - [ ] Filtros: sucursal, categor铆a, proveedor
   - [ ] Conversi贸n 1-click: Sugerencia 鈫?Solicitud 鈫?Orden

4. 鉁?**Simulador de Costo** (2 d铆as)
   - [ ] "驴Qu茅 pasa si ordeno X cantidad?"
   - [ ] Proyecci贸n de cobertura
   - [ ] Alertas de ruptura de stock (si lead time > cobertura)

**Modelo de Datos**:
```sql
CREATE TABLE selemti.stock_policies (
    id BIGSERIAL PRIMARY KEY,
    item_id VARCHAR(20) REFERENCES selemti.items(id),
    sucursal_id BIGINT REFERENCES selemti.cat_sucursales(id),
    stock_min NUMERIC(10,3),
    stock_max NUMERIC(10,3),
    safety_stock NUMERIC(10,3),
    lead_time_days INTEGER,
    replenishment_method VARCHAR(20), -- 'MIN_MAX', 'SMA', 'POS_CONSUMPTION'
    sma_days INTEGER DEFAULT 30, -- Para SMA
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(item_id, sucursal_id)
);

CREATE TABLE selemti.replenishment_runs (
    id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT REFERENCES selemti.cat_sucursales(id),
    fecha DATE,
    estado VARCHAR(20), -- 'DRAFT', 'APPROVED', 'ORDERED'
    total_items INTEGER,
    total_sugerido NUMERIC(15,2),
    created_by_user_id BIGINT REFERENCES selemti.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE selemti.replenishment_lines (
    id BIGSERIAL PRIMARY KEY,
    run_id BIGINT REFERENCES selemti.replenishment_runs(id),
    item_id VARCHAR(20) REFERENCES selemti.items(id),
    stock_actual NUMERIC(10,3),
    stock_min NUMERIC(10,3),
    stock_max NUMERIC(10,3),
    consumo_promedio NUMERIC(10,3),
    qty_sugerida NUMERIC(10,3),
    qty_ajustada NUMERIC(10,3), -- Si usuario edita
    cobertura_dias NUMERIC(5,1),
    razon_calculo TEXT, -- "Min-Max: stock bajo m铆nimo"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Job As铆ncrono**:
```php
// app/Jobs/GenerateReplenishmentSuggestions.php
class GenerateReplenishmentSuggestions implements ShouldQueue
{
    public function handle(ReplenishmentEngine $engine)
    {
        $sucursal = $this->sucursal_id;
        $policies = StockPolicy::where('sucursal_id', $sucursal)
                               ->where('activo', true)
                               ->get();
        
        foreach ($policies as $policy) {
            $suggestion = $engine->calculate($policy);
            ReplenishmentLine::create($suggestion);
        }
    }
}
```

**Entregables**:
- 鉁?Motor de replenishment funcionando
- 鉁?Pol铆ticas de stock configurables
- 鉁?UI de sugerencias con raz贸n del c谩lculo
- 鉁?PR: `feat/replenishment-engine-v7`

**Criterios de Aceptaci贸n**:
- [ ] "Generar Sugerencias" llena grilla con cantidades calculadas
- [ ] Usuario puede ver raz贸n del c谩lculo (tooltip)
- [ ] Sugerencias se convierten a solicitud/orden
- [ ] Integraci贸n POS funciona (read-only)
- [ ] Tests de motor con m煤ltiples m茅todos

---

#### **SPRINT 2.5: Reportes + Quick Wins** (1 semana)
**Objetivo**: Reportes exportables y quick wins de alto impacto

**Tareas**:

1. 鉁?**Export de Reportes** (3 d铆as) 猸?
   - [ ] Export CSV (todos los reportes)
   - [ ] Export PDF (reportes principales)
   - [ ] Usar Laravel Excel o TCPDF
   - [ ] Bot贸n "Exportar" en cada reporte

2. 鉁?**Drill-down en Dashboard** (2 d铆as)
   - [ ] Click en KPI 鈫?detalle
   - [ ] Ejemplo: "Ventas $50k" 鈫?lista de tickets

3. 鉁?**B煤squeda Global (Ctrl+K)** (2 d铆as) 猸?
   - [ ] Alpine.js modal
   - [ ] Busca: 铆tems, recetas, 贸rdenes, usuarios
   - [ ] Resultados agrupados por tipo
   - [ ] Navegaci贸n r谩pida

4. 鉁?**Acciones en Lote** (1 d铆a)
   - [ ] Checkbox en tablas
   - [ ] "Seleccionar todos"
   - [ ] Acciones: Eliminar, Activar/Desactivar, Export

**Entregables**:
- 鉁?Exports CSV/PDF funcionando
- 鉁?B煤squeda global Ctrl+K
- 鉁?Acciones en lote en tablas
- 鉁?PR: `feat/reports-quick-wins-v7`

**Criterios de Aceptaci贸n**:
- [ ] Usuario puede exportar cualquier reporte
- [ ] B煤squeda global responde < 500ms
- [ ] Acciones en lote funcionan en todas las tablas

---

#### **SPRINT 3: Recepciones Avanzadas + FEFO** (1-2 semanas)
**Objetivo**: Recepciones con FEFO y trazabilidad completa

**Tareas**:

1. 鉁?**Auto-lookup por C贸digo Proveedor** (2 d铆as)
   - [ ] Input SKU proveedor 鈫?busca 铆tem
   - [ ] Suggest autom谩tico

2. 鉁?**Conversi贸n Autom谩tica con Tooltip** (2 d铆as)
   - [ ] UOM compra 鈫?UOM base (autom谩tico)
   - [ ] Tooltip mostrando factor: "1 caja = 12 unidades"

3. 鉁?**Adjuntos M煤ltiples** (3 d铆as)
   - [ ] Drag & drop
   - [ ] Preview de im谩genes
   - [ ] Storage en `storage/app/recepciones/`

4. 鉁?**OCR para Lote/Caducidad** (4 d铆as) - OPCIONAL
   - [ ] Tesseract.js o servicio cloud
   - [ ] Extraer fecha y lote de foto
   - [ ] Validaci贸n manual

5. 鉁?**Plantillas de Recepci贸n** (2 d铆as)
   - [ ] Guardar recepci贸n frecuente como plantilla
   - [ ] "Cargar plantilla" 鈫?pre-llena l铆neas

**Entregables**:
- 鉁?Recepciones con adjuntos
- 鉁?Conversi贸n autom谩tica UOM
- 鉁?Plantillas funcionando
- 鉁?PR: `feat/advanced-receptions-v7`

---

#### **SPRINT 4: Recetas + Versionado + Costos Pro** (2 semanas)
**Objetivo**: Recetas con versionado y snapshots de costo

**Tareas**:

1. 鉁?**Versionado de Recetas** (5 d铆as) 猸?
   - [ ] `recipe_version` con n煤mero incremental
   - [ ] Al editar receta 鈫?crear nueva versi贸n
   - [ ] Historial de versiones (UI)
   - [ ] Comparador de versiones (diff)

2. 鉁?**Snapshot de Costo** (3 d铆as)
   - [ ] Al cambiar costo de insumo 鈫?recalcular todas las recetas que lo usan
   - [ ] Job as铆ncrono: `RecalculateRecipeCosts`
   - [ ] Guardar en `recipe_cost_snapshot`
   - [ ] UI: historial de costos con gr谩fica

3. 鉁?**Alertas de Costo** (2 d铆as)
   - [ ] Umbral configurable (ej: +5%)
   - [ ] Notificaci贸n en dashboard
   - [ ] Email opcional

4. 鉁?**Impacto de Costo** (3 d铆as)
   - [ ] Simulador: "驴Qu茅 pasa si sube 10% la leche?"
   - [ ] Tabla de impacto por receta
   - [ ] Sugerencia de ajuste de precio

**Modelo de Datos**:
```sql
CREATE TABLE selemti.recipe_version (
    id BIGSERIAL PRIMARY KEY,
    receta_id VARCHAR(20) REFERENCES selemti.receta_cab(id),
    version INTEGER,
    nombre_plato VARCHAR(200),
    activo BOOLEAN DEFAULT true,
    notas TEXT,
    created_by_user_id BIGINT REFERENCES selemti.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(receta_id, version)
);

CREATE TABLE selemti.recipe_cost_snapshot (
    id BIGSERIAL PRIMARY KEY,
    version_id BIGINT REFERENCES selemti.recipe_version(id),
    costo_total NUMERIC(15,4),
    costo_por_porcion NUMERIC(15,4),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    trigger_reason VARCHAR(50) -- 'INGREDIENT_COST_CHANGE', 'MANUAL', 'SCHEDULED'
);

CREATE TABLE selemti.yield_profile (
    id BIGSERIAL PRIMARY KEY,
    receta_id VARCHAR(20) REFERENCES selemti.receta_cab(id),
    rendimiento_esperado NUMERIC(10,3),
    rendimiento_real NUMERIC(10,3),
    merma_porcentaje NUMERIC(5,2),
    fecha_medicion DATE,
    notas TEXT
);
```

**Job**:
```php
// app/Jobs/RecalculateRecipeCosts.php
class RecalculateRecipeCosts implements ShouldQueue
{
    public function handle(CostingService $costing)
    {
        $recipes = Recipe::whereHas('ingredients', function ($q) {
            $q->where('item_id', $this->item_id_changed);
        })->get();
        
        foreach ($recipes as $recipe) {
            $newCost = $costing->calculateRecipeCost($recipe);
            
            RecipeCostSnapshot::create([
                'version_id' => $recipe->activeVersion->id,
                'costo_total' => $newCost,
                'trigger_reason' => 'INGREDIENT_COST_CHANGE'
            ]);
            
            // Alerta si cambi贸 > 5%
            if ($this->costChangedMoreThan($recipe, 5)) {
                event(new CostAlertTriggered($recipe, $newCost));
            }
        }
    }
}
```

**Entregables**:
- 鉁?Versionado de recetas
- 鉁?Snapshots autom谩ticos
- 鉁?Alertas de costo funcionando
- 鉁?PR: `feat/recipe-versioning-costs-v7`

**Criterios de Aceptaci贸n**:
- [ ] Al cambiar costo de insumo, recetas se recalculan autom谩ticamente
- [ ] Usuario ve historial de costos con gr谩fica
- [ ] Alertas se generan cuando costo cambia > umbral
- [ ] Simulador de impacto funciona

---

#### **SPRINT 5: Transferencias + Discrepancias** (1 semana)
**Objetivo**: Transferencias con recepci贸n y ajustes

**Tareas**:

1. 鉁?**Flujo 3 Estados** (3 d铆as)
   - [ ] Borrador 鈫?Despachada 鈫?Recibida
   - [ ] Al despachar: descuenta origen, crea "en tr谩nsito"
   - [ ] Al recibir: abona destino por lote

2. 鉁?**Confirmaci贸n Parcial** (2 d铆as)
   - [ ] Recibir menos de lo enviado
   - [ ] Raz贸n de discrepancia (dropdown)

3. 鉁?**Bot贸n "Recibir" en Destino** (2 d铆as)
   - [ ] Sucursal destino puede ver transferencias pendientes
   - [ ] Click "Recibir" 鈫?posteo

**Modelo de Datos**:
```sql
CREATE TABLE selemti.transfer_discrepancy (
    id BIGSERIAL PRIMARY KEY,
    transfer_id BIGINT REFERENCES selemti.traspaso_cab(id),
    item_id VARCHAR(20) REFERENCES selemti.items(id),
    qty_esperada NUMERIC(10,3),
    qty_recibida NUMERIC(10,3),
    razon VARCHAR(50), -- 'DAMAGED', 'LOST', 'SHORT', 'EXCESS'
    notas TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Entregables**:
- 鉁?Transferencias con 3 estados
- 鉁?Discrepancias manejadas
- 鉁?PR: `feat/transfers-discrepancies-v7`

---

#### **SPRINT 6: Producci贸n UI** (1-2 semanas)
**Objetivo**: UI operativa para 贸rdenes de producci贸n

**Tareas**:

1. 鉁?**Planificaci贸n de OP** (4 d铆as)
   - [ ] Por demanda (ventas POS)
   - [ ] Por stock objetivo
   - [ ] Por calendario (programadas)

2. 鉁?**Consumo Te贸rico vs Real** (3 d铆as)
   - [ ] Al crear OP: calcular consumo te贸rico
   - [ ] Al cerrar OP: registrar consumo real
   - [ ] Comparaci贸n con merma

3. 鉁?**KPIs de Producci贸n** (2 d铆as)
   - [ ] Rendimiento (output/input)
   - [ ] Merma %
   - [ ] Costo por batch

4. 鉁?**Cierre de OP** (3 d铆as)
   - [ ] Validaci贸n: stock suficiente
   - [ ] Posteo: descuenta MP, abona PT
   - [ ] Genera `mov_inv`

**Modelo de Datos**:
```sql
CREATE TABLE selemti.production_batch (
    id BIGSERIAL PRIMARY KEY,
    receta_id VARCHAR(20) REFERENCES selemti.receta_cab(id),
    sucursal_id BIGINT REFERENCES selemti.cat_sucursales(id),
    qty_planeada NUMERIC(10,3),
    qty_producida NUMERIC(10,3),
    estado VARCHAR(20), -- 'DRAFT', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
    fecha_inicio TIMESTAMP,
    fecha_fin TIMESTAMP,
    created_by_user_id BIGINT REFERENCES selemti.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE selemti.production_consumption (
    id BIGSERIAL PRIMARY KEY,
    batch_id BIGINT REFERENCES selemti.production_batch(id),
    item_id VARCHAR(20) REFERENCES selemti.items(id),
    qty_teorica NUMERIC(10,3),
    qty_real NUMERIC(10,3),
    merma NUMERIC(10,3) GENERATED ALWAYS AS (qty_real - qty_teorica) STORED
);

CREATE TABLE selemti.production_output (
    id BIGSERIAL PRIMARY KEY,
    batch_id BIGINT REFERENCES selemti.production_batch(id),
    producto_id VARCHAR(20), -- Producto terminado
    qty NUMERIC(10,3)
);
```

**Entregables**:
- 鉁?UI de producci贸n operativa
- 鉁?Cierre de OP con posteo
- 鉁?KPIs de rendimiento
- 鉁?PR: `feat/production-ui-v7`

---

#### **SPRINT 7: Mobile + Barcode** (1-2 semanas) - OPCIONAL
**Objetivo**: Experiencia mobile para operaciones

**Tareas**:

1. 鉁?**UI Mobile-first para Conteos** (5 d铆as)
   - [ ] Responsive design
   - [ ] Escaneo de c贸digo de barras (QuaggaJS)
   - [ ] Ajuste de qty con +/-

2. 鉁?**Etiquetas/Barcode** (3 d铆as)
   - [ ] Generaci贸n de c贸digos de barras
   - [ ] Impresi贸n de etiquetas

3. 鉁?**PWA** (3 d铆as) - OPCIONAL
   - [ ] Service worker
   - [ ] Offline-first
   - [ ] Install prompt

**Entregables**:
- 鉁?App mobile para conteos
- 鉁?Barcode scanning
- 鉁?PR: `feat/mobile-barcode-v7`

---

### 5.3 Resumen de Sprints

| Sprint | Duraci贸n | Prioridad | Impacto Negocio |
|--------|----------|-----------|-----------------|
| Sprint 0: Foundation | 1-2 sem | 馃敟 CR脥TICO | Alto |
| Sprint 1: Inventario Base | 2 sem | 馃敟 CR脥TICO | Alto |
| Sprint 2: Replenishment 馃敟 | 2-3 sem | 馃敟 CR脥TICO | MUY ALTO |
| Sprint 2.5: Reportes + Quick Wins | 1 sem | 鈿狅笍 ALTO | Medio-Alto |
| Sprint 3: Recepciones Avanzadas | 1-2 sem | 鈿狅笍 ALTO | Medio |
| Sprint 4: Recetas + Costos | 2 sem | 鈿狅笍 ALTO | Alto |
| Sprint 5: Transferencias | 1 sem | 鈿狅笍 MEDIO | Medio |
| Sprint 6: Producci贸n UI | 1-2 sem | 鈿狅笍 MEDIO | Medio (depende del negocio) |
| Sprint 7: Mobile + Barcode | 1-2 sem | 馃煝 BAJO | Bajo-Medio |

**Total estimado**: 12-18 semanas (3-4.5 meses)

---

## 6. AN脕LISIS POR M脫DULO

*(continuar谩 con an谩lisis detallado de cada m贸dulo, componentes espec铆ficos, wireframes, etc.)*

---

## 7. QUICK WINS (Bajo Esfuerzo, Alto Impacto)

### Semana 1:
1. 鉁?**Validaci贸n inline** (2 d铆as)
2. 鉁?**Toasts con detalle** (1 d铆a)
3. 鉁?**Empty states** (1 d铆a)
4. 鉁?**Loading skeletons** (1 d铆a)

### Semana 2:
1. 鉁?**Export CSV** (2 d铆as)
2. 鉁?**B煤squeda global Ctrl+K** (2 d铆as)
3. 鉁?**Acciones en lote** (1 d铆a)

### Semana 3-4:
1. 鉁?**Wizard de alta item** (3 d铆as)
2. 鉁?**Auto-conversi贸n UOM** (2 d铆as)
3. 鉁?**Snapshot de costos** (2 d铆as)
4. 鉁?**Pol铆ticas de stock UI** (2 d铆as)

---

## 8. M脡TRICAS Y KPIs

### KPIs de Desarrollo

| M茅trica | Objetivo | Actual | Gap |
|---------|----------|--------|-----|
| Cobertura de Tests | 80% | 30%? | +50% |
| Tiempo de Carga (p95) | < 2s | 3-5s? | -1-3s |
| Errores JS (producci贸n) | < 5/d铆a | ? | TBD |
| Uptime | 99.5% | ? | TBD |

### KPIs de Negocio

| M茅trica | Objetivo | M茅todo |
|---------|----------|--------|
| Reducci贸n de ruptura de stock | -50% | Motor replenishment |
| Tiempo de conteo f铆sico | -30% | Mobile app |
| Precisi贸n de costos | +95% | Snapshots autom谩ticos |
| Tiempo de cierre diario | -20 min | Automatizaci贸n |

---

## 9. PLAN DE TESTING

### Testing Unitario (PHPUnit)
```php
tests/Unit/
鈹溾攢鈹€ Services/
鈹?  鈹溾攢鈹€ ReplenishmentEngineTest.php 猸?
鈹?  鈹溾攢鈹€ CostingServiceTest.php 猸?
鈹?  鈹斺攢鈹€ RecipeServiceTest.php
鈹斺攢鈹€ Jobs/
    鈹斺攢鈹€ RecalculateRecipeCostsTest.php
```

### Testing de Integraci贸n
```php
tests/Feature/
鈹溾攢鈹€ Inventory/
鈹?  鈹溾攢鈹€ ItemCreationTest.php
鈹?  鈹溾攢鈹€ ReceptionPostingTest.php
鈹?  鈹斺攢鈹€ TransferFlowTest.php
鈹溾攢鈹€ Purchasing/
鈹?  鈹斺攢鈹€ ReplenishmentFlowTest.php 猸?
鈹斺攢鈹€ Recipes/
    鈹斺攢鈹€ CostRecalculationTest.php 猸?
```

### Testing E2E (Laravel Dusk)
```php
tests/Browser/
鈹溾攢鈹€ InventoryFlowTest.php
鈹溾攢鈹€ ReplenishmentFlowTest.php
鈹斺攢鈹€ ProductionFlowTest.php
```

---

## 10. ENTREGABLES

### Por Sprint:
1. 鉁?**PR con c贸digo** (branch feat/*)
2. 鉁?**Tests pasando** (PHPUnit + Dusk)
3. 鉁?**Documentaci贸n** (README + inline)
4. 鉁?**Screenshots/Video** (evidencia)
5. 鉁?**Migration scripts** (si aplica)
6. 鉁?**Seeder data** (datos de prueba)

### Finales:
1. 鉁?**Manual de Usuario** (PDF)
2. 鉁?**Gu铆a de Desarrollo** (para mantenimiento)
3. 鉁?**Documentaci贸n API** (Postman/Swagger)
4. 鉁?**Videos de Capacitaci贸n** (por m贸dulo)
5. 鉁?**Plan de Rollback** (por si falla)

---

## 馃摓 CONTACTO Y PR脫XIMOS PASOS

### Decisiones Pendientes:

1. **驴Cu谩l es la prioridad #1 del negocio?**
   - Evitar rupturas 鈫?Priorizar Replenishment
   - Control de costos 鈫?Priorizar Recetas + Snapshots
   - Producci贸n interna 鈫?Priorizar Producci贸n UI

2. **驴Tienes equipo frontend o eres solo?**
   - Ajustar timeline seg煤n recursos

3. **驴Prefieres enfoque 谩gil (sprints) o MVP r谩pido?**
   - MVP = Sprint 0 + 1 + 2 (6-8 semanas)
   - 脕gil = Todos los sprints (12-18 semanas)

4. **驴El negocio es m谩s retail o producci贸n?**
   - Retail 鈫?Priorizar Inventario + Compras
   - Producci贸n 鈫?Priorizar Recetas + Producci贸n

---

**Fecha de Creaci贸n**: 31 de octubre de 2025, 02:30  
**Versi贸n**: v7.0 Enterprise  
**Estado**: 馃煝 LISTO PARA EJECUTAR

**Base de Datos**: 鉁?Enterprise-grade completada (31 oct 00:40)  
**Frontend**: 鈴?Pendiente de implementaci贸n (este plan)

---

*Documento creado en base a:*
- 鉁?Auditor铆a UI/UX (AuditoriaGPT.txt)
- 鉁?MASTER_ROADMAP_V6.md
- 鉁?PERMISSIONS_MATRIX_V6.md
- 鉁?UI_GATING_MAP_V6.md
- 鉁?PERMISSIONS_SEEDER_V6.php
- 鉁?SEED_PLANTILLAS_V6.sql
- 鉁?An谩lisis experto (Claude AI)
- 鉁?Base de Datos Enterprise v7.0 (reci茅n completada)

**隆Sistema listo para transformarse en ERP de clase mundial! 馃殌**
