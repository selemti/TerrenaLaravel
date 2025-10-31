# 🎯 PLAN MAESTRO UI/UX ENTERPRISE - TerrenaLaravel

**Proyecto**: TerrenaLaravel - Sistema ERP Restaurantes  
**Versión**: v7.0 Enterprise (Post-Normalización BD)  
**Fecha**: 31 de octubre de 2025  
**Estado**: 🟢 READY TO EXECUTE

---

## 📋 TABLA DE CONTENIDOS

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Estado Actual](#estado-actual)
3. [Arquitectura y Stack](#arquitectura-y-stack)
4. [Sistema de Permisos](#sistema-de-permisos)
5. [Roadmap de Implementación](#roadmap-de-implementación)
6. [Análisis por Módulo](#análisis-por-módulo)
7. [Quick Wins](#quick-wins)
8. [Métricas y KPIs](#métricas-y-kpis)
9. [Plan de Testing](#plan-de-testing)
10. [Entregables](#entregables)

---

## 1. RESUMEN EJECUTIVO

### 🎉 Logro Mayor: Base de Datos Enterprise Completada

**Acabamos de completar** (31 octubre 2025, 00:40):
- ✅ **5 Fases de normalización** (Fundamentos → Consolidación → Integridad → Performance → Enterprise)
- ✅ **141 tablas** enterprise-grade
- ✅ **127 Foreign Keys** verificadas
- ✅ **415 índices** optimizados
- ✅ **20 triggers** de auditoría
- ✅ **51 vistas** de compatibilidad
- ✅ **4 vistas materializadas** para reportes
- ✅ **Audit log global** implementado
- ✅ **Zero breaking changes** + código legacy compatible

### 🎯 Objetivo del Plan UI/UX

Transformar el frontend de un sistema funcional a un **ERP comercial de clase mundial** aprovechando la base de datos enterprise que acabamos de crear.

### 📊 Estado Actual vs Objetivo

| Módulo | Estado Actual | Objetivo | Gap |
|--------|---------------|----------|-----|
| **Inventario** | 60-70% | 95% | UI moderna + validaciones |
| **Compras/Replenishment** | 40-50% | 95% | Motor + políticas |
| **Recetas/Costos** | 50-60% | 95% | Versionado + snapshots |
| **Producción** | 30-40% | 90% | UI operativa completa |
| **POS Integration** | 70% | 95% | Auditoría + mapeos |
| **Reportes** | 30-40% | 90% | Exports + drill-down |
| **Permisos** | 80% | 98% | Matriz + gating |
| **Caja Chica** | 70% | 90% | Reglas + checklist |

### 🚀 Ventaja Competitiva

Con la BD enterprise completada, tenemos:
1. ✅ **Integridad garantizada** por constraints de BD
2. ✅ **Auditoría automática** vía triggers
3. ✅ **Performance optimizada** con 415 índices
4. ✅ **Escalabilidad** probada (vistas materializadas)
5. ✅ **Código legacy compatible** (vistas v_*)

**Esto significa**: El frontend puede ser **más simple y rápido** porque la BD hace el trabajo pesado.

---

## 2. ESTADO ACTUAL

### 2.1 Stack Tecnológico Actual

```
Backend:
├── Laravel 10.x
├── PHP 8.2+
├── PostgreSQL 9.5
└── Spatie Permissions (roles/permisos)

Frontend:
├── Blade Templates
├── Alpine.js (interactividad)
├── Tailwind CSS 3.x
├── Bootstrap 5 (legacy, migrar gradualmente)
└── Livewire (componentes reactivos)

Infraestructura:
├── XAMPP (desarrollo)
├── Git (control de versiones)
└── Artisan (CLI)
```

### 2.2 Módulos Existentes

**Inventario**:
- ✅ Items/Altas: Filtro + alta básica
- ✅ Recepciones: Modal completo con FEFO
- ✅ Lotes/Caducidades: Tableros vacíos
- ✅ Conteos: Estados + tablero
- ✅ Transferencias: Borrador/Despachada

**Compras**:
- ✅ Solicitudes/Órdenes: Estructura completa
- ⚠️ Pedidos Sugeridos: UI lista, motor falta
- ⚠️ Políticas de Stock: UI pendiente

**Recetas**:
- ✅ Listado con precios
- ✅ Editor básico (ID, PLU, ingredientes)
- ⚠️ Alertas de costo vacío
- ❌ Versionado: No implementado
- ❌ Snapshots automáticos: Falta

**Producción**:
- ✅ API completa (plan/consume/complete/post)
- ❌ UI operativa: No existe

**POS**:
- ✅ Mapeos: Vista básica
- ⚠️ Auditoría: Queries v6 listas, UI falta
- ✅ Integración read-only desde `public.*`

**Caja Chica**:
- ✅ Precorte por denominaciones
- ✅ Panel de excepciones
- ⚠️ Reglas parametrizables: Falta

**Reportes**:
- ✅ Dashboard principal con KPIs ventas
- ❌ Exports CSV/PDF: No
- ❌ Drill-down: No
- ❌ Reportes programados: No

**Catálogos**:
- ✅ Sucursales, Almacenes: Completo
- ✅ Unidades/Conversiones: Muy bien
- ✅ Proveedores: Básico
- ⚠️ Políticas de Stock: UI pendiente

**Permisos**:
- ✅ 45 permisos definidos
- ✅ 9 módulos
- ✅ 7 roles base
- ⚠️ Matriz visual: Falta
- ⚠️ Auditoría de cambios: Falta

### 2.3 Fortalezas Actuales

1. ✅ **Base de Datos Enterprise** (recién completada)
2. ✅ **Estructura Laravel sólida**
3. ✅ **Spatie Permissions** implementado
4. ✅ **Alpine.js + Livewire** (moderno, rápido)
5. ✅ **Tailwind CSS** (diseño consistente)
6. ✅ **API REST** bien estructurada
7. ✅ **Integración POS** read-only funcional

### 2.4 Gaps Críticos Identificados

| Prioridad | Gap | Impacto Negocio | Esfuerzo |
|-----------|-----|-----------------|----------|
| 🔥 **CRÍTICO** | Motor de Replenishment | ALTO | MEDIO |
| 🔥 **CRÍTICO** | Snapshot de Costos (auto) | ALTO | BAJO |
| 🔥 **CRÍTICO** | Validaciones inline | MEDIO | BAJO |
| ⚠️ **ALTO** | Versionado de Recetas | ALTO | MEDIO |
| ⚠️ **ALTO** | Export Reportes | MEDIO | BAJO |
| ⚠️ **ALTO** | UI Producción | MEDIO | ALTO |
| ⚠️ **MEDIO** | Políticas de Stock UI | ALTO | MEDIO |
| ⚠️ **MEDIO** | Auditoría POS UI | MEDIO | BAJO |
| 🟢 **BAJO** | Mobile conteos | BAJO | MEDIO |
| 🟢 **BAJO** | OCR lotes | BAJO | ALTO |

---

## 3. ARQUITECTURA Y STACK

### 3.1 Arquitectura Propuesta (Layers)

```
┌─────────────────────────────────────────────────────┐
│                    PRESENTATION                      │
│  Blade + Alpine.js + Livewire + Tailwind CSS       │
│  • Validación inline (Alpine)                       │
│  • Componentes reactivos (Livewire)                 │
│  • UI consistente (Tailwind)                        │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│                   APPLICATION                        │
│  Controllers (HTTP) + Livewire Components           │
│  • Routing                                          │
│  • Request validation                               │
│  • Response formatting                              │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│                     BUSINESS                         │
│  Services (lógica de negocio)                       │
│  ├── ItemService                                    │
│  ├── CostingService                                 │
│  ├── ReplenishmentEngine ⭐                         │
│  ├── RecipeService                                  │
│  ├── ProductionService                              │
│  ├── TransferService                                │
│  └── ReportingService                               │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│                     DATA ACCESS                      │
│  Models (Eloquent ORM)                              │
│  • Relationships                                    │
│  • Scopes                                           │
│  • Accessors/Mutators                               │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│                    DATABASE ✅                       │
│  PostgreSQL 9.5 - ENTERPRISE GRADE                  │
│  • 141 tablas                                       │
│  • 127 FKs                                          │
│  • 415 índices                                      │
│  • 20 triggers                                      │
│  • Audit log global                                 │
└─────────────────────────────────────────────────────┘
```

### 3.2 Patrones de Diseño

**1. Repository Pattern** (opcional, para queries complejas):
```php
app/Repositories/
├── ItemRepository
├── RecipeRepository
└── ReportRepository
```

**2. Service Layer Pattern** (obligatorio):
```php
app/Services/
├── Inventory/
│   ├── ItemService.php
│   ├── ReceptionService.php
│   └── TransferService.php
├── Purchasing/
│   ├── ReplenishmentEngine.php ⭐
│   └── OrderService.php
├── Recipes/
│   ├── RecipeService.php
│   └── CostingService.php ⭐
└── Production/
    └── ProductionService.php
```

**3. Job/Queue Pattern** (asíncrono):
```php
app/Jobs/
├── RecalculateRecipeCosts.php ⭐
├── GenerateReplenishmentSuggestions.php ⭐
├── UpdateCostSnapshots.php
├── ProcessPosConsumption.php
└── GenerateReports.php
```

**4. Event/Listener Pattern** (auditoría):
```php
app/Events/
├── ItemCreated.php
├── CostChanged.php
├── RecipeUpdated.php
└── StockBelowMinimum.php

app/Listeners/
├── LogItemCreation.php
├── RecalculateRecipeCosts.php
├── NotifyStockAlert.php
└── UpdateCostSnapshot.php
```

### 3.3 Estructura de Directorios Propuesta

```
app/
├── Http/
│   ├── Controllers/          (delgados, solo routing)
│   │   ├── InventoryController.php
│   │   ├── PurchasingController.php
│   │   ├── RecipeController.php
│   │   └── ProductionController.php
│   ├── Livewire/            (componentes reactivos)
│   │   ├── Inventory/
│   │   │   ├── ItemForm.php
│   │   │   ├── ItemList.php
│   │   │   ├── ReceptionForm.php
│   │   │   └── CountingForm.php
│   │   ├── Purchasing/
│   │   │   ├── SuggestedOrders.php ⭐
│   │   │   └── StockPolicies.php
│   │   └── Recipes/
│   │       ├── RecipeEditor.php
│   │       └── CostAlert.php
│   ├── Middleware/
│   │   ├── CheckPermission.php ⭐
│   │   └── AuditLog.php
│   └── Requests/            (validación)
│       ├── StoreItemRequest.php
│       └── PostReceptionRequest.php
├── Services/                (lógica de negocio) ⭐
├── Jobs/                    (procesamiento asíncrono) ⭐
├── Events/                  (eventos del sistema)
├── Listeners/               (respuestas a eventos)
├── Models/                  (Eloquent ORM)
│   ├── Item.php
│   ├── InventoryBatch.php
│   ├── Recipe.php
│   ├── RecipeVersion.php ⭐
│   └── StockPolicy.php ⭐
└── Policies/                (autorización) ⭐
    ├── InventoryPolicy.php
    ├── PurchasingPolicy.php
    ├── RecipePolicy.php
    └── ProductionPolicy.php

resources/
├── views/
│   ├── components/          (Blade components reusables) ⭐
│   │   ├── forms/
│   │   │   ├── input.blade.php
│   │   │   ├── select.blade.php
│   │   │   └── datepicker.blade.php
│   │   ├── ui/
│   │   │   ├── toast.blade.php ⭐
│   │   │   ├── modal.blade.php
│   │   │   ├── card.blade.php
│   │   │   ├── empty-state.blade.php ⭐
│   │   │   └── loading-skeleton.blade.php ⭐
│   │   └── tables/
│   │       ├── table.blade.php
│   │       └── pagination.blade.php
│   ├── livewire/            (vistas Livewire)
│   ├── inventory/
│   ├── purchasing/
│   ├── recipes/
│   └── layouts/
│       ├── app.blade.php
│       ├── guest.blade.php
│       └── components/
│           ├── navbar.blade.php
│           ├── sidebar.blade.php ⭐
│           └── breadcrumb.blade.php
└── js/
    ├── alpine/              (Alpine.js components)
    │   ├── validation.js ⭐
    │   ├── search.js
    │   └── modals.js
    └── app.js

database/
├── migrations/              (nuevas tablas)
│   ├── 2025_11_01_create_stock_policies_table.php ⭐
│   ├── 2025_11_01_create_replenishment_runs_table.php ⭐
│   ├── 2025_11_01_create_recipe_versions_table.php ⭐
│   ├── 2025_11_01_create_recipe_cost_snapshots_table.php ⭐
│   └── 2025_11_01_create_production_batches_table.php
└── seeders/
    ├── PermissionsSeederV6.php ⭐
    └── StockPoliciesSeeder.php
```

---

## 4. SISTEMA DE PERMISOS

### 4.1 Arquitectura de Permisos (Spatie)

**Jerarquía**:
```
Usuario
  ↓
Roles (plantillas)
  ↓
Permisos (atómicos)
  ↓
Gates (autorización)
  ↓
UI Gating (mostrar/ocultar)
```

### 4.2 Permisos Atómicos (44 permisos)

#### **Inventario** (14 permisos)
```
inventory.items.view              → Ver catálogo de ítems
inventory.items.manage            → Crear/Editar ítems
inventory.uoms.view               → Ver presentaciones
inventory.uoms.manage             → Gestionar presentaciones
inventory.uoms.convert.manage     → Gestionar conversiones
inventory.receptions.view         → Ver recepciones
inventory.receptions.post         → Postear recepciones (mov_inv)
inventory.counts.view             → Ver conteos
inventory.counts.open             → Abrir conteo
inventory.counts.close            → Cerrar conteo (valida v6)
inventory.moves.view              → Ver movimientos
inventory.moves.adjust            → Ajuste manual
inventory.snapshot.generate       → Generar snapshot diario
inventory.snapshot.view           → Ver snapshots
```

#### **Compras** (3 permisos)
```
purchasing.suggested.view         → Ver pedidos sugeridos
purchasing.orders.manage          → Crear/Editar órdenes
purchasing.orders.approve         → Aprobar órdenes
```

#### **Recetas/Costos** (4 permisos)
```
recipes.view                      → Ver recetas
recipes.manage                    → Crear/Editar recetas
recipes.costs.recalc.schedule     → Cron recalcular costos (01:10)
recipes.costs.snapshot            → Snapshot manual de costo
```

#### **POS** (4 permisos)
```
pos.map.view                      → Ver mapeos POS
pos.map.manage                    → Gestionar mapeos
pos.audit.run                     → Ejecutar auditoría SQL v6
pos.reprocess.run                 → Reprocesar tickets
```

#### **Producción** (2 permisos)
```
production.orders.view            → Ver órdenes de producción
production.orders.close           → Cerrar OP (consume MP)
```

#### **Caja** (2 permisos)
```
cashier.preclose.run              → Ejecutar precorte
cashier.close.run                 → Corte final
```

#### **Reportes** (2 permisos)
```
reports.kpis.view                 → Ver KPIs/dashboard
reports.audit.view                → Ver auditoría
```

#### **Sistema** (3 permisos)
```
system.users.view                 → Ver usuarios
system.templates.manage           → Gestionar plantillas de roles
system.permissions.direct.manage  → Asignar permisos especiales
```

### 4.3 Plantillas de Roles (7 roles predefinidos)

**1. Almacenista** (6 permisos):
```
✅ inventory.items.view
✅ inventory.counts.view
✅ inventory.counts.open
✅ inventory.counts.close
✅ inventory.moves.view
✅ inventory.snapshot.view
```

**Caso de uso**: Operador de almacén que realiza conteos físicos.

---

**2. Jefe de Almacén** (9 permisos):
```
✅ inventory.items.view
✅ inventory.counts.view
✅ inventory.counts.open
✅ inventory.counts.close
✅ inventory.moves.view
✅ inventory.moves.adjust          ← Ajustes manuales
✅ inventory.receptions.view
✅ inventory.receptions.post       ← Posteo de recepciones
✅ pos.map.view
```

**Caso de uso**: Supervisor de almacén con capacidad de ajustar inventario.

---

**3. Compras** (4 permisos):
```
✅ purchasing.suggested.view
✅ purchasing.orders.manage
✅ purchasing.orders.approve       ← Autorización de compras
✅ inventory.receptions.view
```

**Caso de uso**: Departamento de compras, manejo de pedidos y proveedores.

---

**4. Costos / Recetas** (5 permisos):
```
✅ recipes.view
✅ recipes.manage
✅ recipes.costs.recalc.schedule   ← Cron automático
✅ recipes.costs.snapshot          ← Snapshot manual
✅ pos.map.manage                  ← Mapeo menú
```

**Caso de uso**: Chef o gerente de costos que gestiona recetas y precios.

---

**5. Producción** (3 permisos):
```
✅ production.orders.view
✅ production.orders.close         ← Cierre de OP
✅ inventory.items.view
```

**Caso de uso**: Operador de producción (si aplica en el negocio).

---

**6. Auditoría / Reportes** (4 permisos):
```
✅ reports.kpis.view
✅ reports.audit.view
✅ pos.audit.run                   ← Auditoría SQL v6
✅ inventory.snapshot.view
```

**Caso de uso**: Contador o gerente general que revisa reportes.

---

**7. Administrador del Sistema** (wildcard):
```
✅ * (todos los permisos)
```

**Caso de uso**: IT o dueño con acceso total.

---

### 4.4 UI Gating Map (visibilidad por permiso)

#### **Inventario**
| Ruta/Elemento | Permiso Requerido | Tipo |
|---------------|-------------------|------|
| `/inventario/items` | `inventory.items.view` | Vista |
| → Botón "Nuevo Ítem" | `inventory.items.manage` | Acción |
| → Acción "Editar" | `inventory.items.manage` | Acción |
| → Acción "Ajuste manual" | `inventory.moves.adjust` | Acción |
| `/inventario/recepciones` | `inventory.receptions.view` | Vista |
| → Botón "Postear" | `inventory.receptions.post` | Acción |
| `/inventario/conteos` | `inventory.counts.view` | Vista |
| → Botón "Abrir conteo" | `inventory.counts.open` | Acción |
| → Botón "Cerrar conteo" | `inventory.counts.close` | Acción |
| `/inventario/snapshot` | `inventory.snapshot.view` | Vista |
| → Botón "Generar snapshot" | `inventory.snapshot.generate` | Acción |

#### **POS**
| Ruta/Elemento | Permiso Requerido | Tipo |
|---------------|-------------------|------|
| `/pos/map` | `pos.map.view` | Vista |
| → Botón "Nuevo mapeo" | `pos.map.manage` | Acción |
| → Acción "Editar mapeo" | `pos.map.manage` | Acción |
| `/pos/auditoria` | `pos.audit.run` | Vista + Acción |
| → Botón "Ejecutar auditoría SQL v6" | `pos.audit.run` | Acción |

#### **Recetas / Costos**
| Ruta/Elemento | Permiso Requerido | Tipo |
|---------------|-------------------|------|
| `/recetas` | `recipes.view` | Vista |
| → Botón "Nueva receta" | `recipes.manage` | Acción |
| → Acción "Snapshot costo" | `recipes.costs.snapshot` | Acción |

#### **Compras**
| Ruta/Elemento | Permiso Requerido | Tipo |
|---------------|-------------------|------|
| `/compras/sugerido` | `purchasing.suggested.view` | Vista |
| `/compras/ordenes` | `purchasing.orders.manage` | Vista |
| → Botón "Nueva orden" | `purchasing.orders.manage` | Acción |
| → Botón "Aprobar" | `purchasing.orders.approve` | Acción |

#### **Producción**
| Ruta/Elemento | Permiso Requerido | Tipo |
|---------------|-------------------|------|
| `/produccion/ordenes` | `production.orders.view` | Vista |
| → Botón "Cerrar OP" | `production.orders.close` | Acción |

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

### 4.5 Implementación en Código

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
    <button wire:click="createItem">Nuevo Ítem</button>
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
        abort(403, 'No tienes permiso para crear ítems.');
    }
    
    // Lógica...
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

## 5. ROADMAP DE IMPLEMENTACIÓN

### 5.1 Visión General (6 meses)

```
Mes 1: Sprint 0 + Sprint 1 (Inventario Base)
Mes 2: Sprint 2 (Replenishment 🔥) + Sprint 2.5 (Reportes)
Mes 3: Sprint 3 (Recepciones Avanzadas) + Sprint 4 (Recetas)
Mes 4: Sprint 5 (Transferencias) + Sprint 6 (Producción)
Mes 5: Sprint 7 (Mobile) + Optimizaciones
Mes 6: Testing QA + Capacitación + Go-Live
```

### 5.2 Sprints Detallados

---

#### **SPRINT 0: Foundation** (1-2 semanas)
**Objetivo**: Crear base sólida de componentes y design system

**Tareas**:
1. ✅ **Design System** (5 días)
   - [ ] Tailwind config personalizado
   - [ ] Paleta de colores consistente
   - [ ] Tipografía y espaciado
   - [ ] Componentes base:
     - [ ] `<x-button>`
     - [ ] `<x-input>`
     - [ ] `<x-select>`
     - [ ] `<x-textarea>`
     - [ ] `<x-datepicker>`
     - [ ] `<x-modal>`
     - [ ] `<x-toast>` ⭐
     - [ ] `<x-card>`
     - [ ] `<x-table>`
     - [ ] `<x-empty-state>` ⭐
     - [ ] `<x-loading-skeleton>` ⭐

2. ✅ **Sistema de Validación Unificado** (3 días)
   - [ ] Validación inline con Alpine.js ⭐
   - [ ] Mensajes de error consistentes
   - [ ] Highlight de campos con error
   - [ ] Tooltips de ayuda

3. ✅ **Sistema de Notificaciones** (2 días)
   - [ ] Toast notifications (éxito/error/warning/info)
   - [ ] Alpine.js store para toasts
   - [ ] Auto-dismiss configurable

4. ✅ **Auditoría Base** (2 días)
   - [ ] Middleware de auditoría
   - [ ] Log de errores estructurado
   - [ ] Eventos CRUD básicos

**Entregables**:
- ✅ Guía de diseño (Figma/PDF)
- ✅ Storybook de componentes
- ✅ Sistema de validación funcionando
- ✅ PR: `feat/design-system-v7`

**Criterios de Aceptación**:
- [ ] Todos los componentes funcionan en producción
- [ ] Guía documentada con ejemplos
- [ ] Tests unitarios de componentes críticos

---

#### **SPRINT 1: Inventario Base + Costos** (2 semanas)
**Objetivo**: Inventario sólido con costos actualizados

**Tareas**:

1. ✅ **Alta de Ítems (Wizard 2 Pasos)** (5 días)
   - [ ] Paso 1: Datos maestros (nombre, categoría, UOM base)
   - [ ] Paso 2: Presentaciones/Proveedor (opcional)
   - [ ] Validación inline por campo ⭐
   - [ ] Preview de código CAT-SUB-##### antes de guardar
   - [ ] Botón "Crear y seguir con presentaciones"
   - [ ] Auto-sugerencias de nombres normalizados

2. ✅ **Proveedor-Insumo (Presentaciones)** (3 días)
   - [ ] CRUD completo
   - [ ] Plantilla rápida desde recepción
   - [ ] Auto-conversión UOM base ↔ compra
   - [ ] Tooltip mostrando factor de conversión

3. ✅ **Recepciones Posteables** (5 días)
   - [ ] Estados: Pre-validada → Aprobada → Posteada
   - [ ] Snapshot de costo al postear ⭐
   - [ ] Adjuntos múltiples (drag & drop)
   - [ ] Tolerancias de qty (alerta si discrepancia > X%)
   - [ ] Genera `mov_inv` automáticamente

4. ✅ **UOM Assistant** (2 días)
   - [ ] Creación inversa automática (si creo kg→g, crear g→kg)
   - [ ] Validación de circularidad
   - [ ] Preview de conversión

**Modelo de Datos Necesario**:
```sql
-- Ya existe en BD:
✅ selemti.items
✅ selemti.inventory_batch

-- Añadir:
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
- ✅ Wizard de ítems funcionando
- ✅ Recepciones con snapshot de costo
- ✅ UOM con conversiones automáticas
- ✅ PR: `feat/inventory-base-v7`

**Criterios de Aceptación**:
- [ ] Usuario puede crear ítem → añadir presentación → recepcionar con conversión automática → ver lote/caducidad → costo base actualizado
- [ ] Tests de integración pasando
- [ ] Validaciones inline funcionando

---

#### **SPRINT 2: Replenishment + Políticas** 🔥 (2-3 semanas)
**Objetivo**: Motor de sugerencias de pedidos (corazón del negocio)

**Tareas**:

1. ✅ **UI de Políticas de Stock** (3 días)
   - [ ] CRUD por ítem/sucursal
   - [ ] Campos:
     - [ ] Stock mínimo
     - [ ] Stock máximo
     - [ ] Safety stock
     - [ ] Lead time (días)
     - [ ] Método de replenishment (dropdown)
   - [ ] Bulk import CSV
   - [ ] Export template

2. ✅ **Motor de Replenishment** (7 días) ⭐⭐⭐
   - [ ] Método 1: Min-Max básico
     ```
     Si stock_actual < min:
         sugerido = max - stock_actual
     ```
   - [ ] Método 2: Simple Moving Average (SMA)
     ```
     consumo_promedio = SUM(consumo_últimos_n_días) / n
     sugerido = (consumo_promedio * lead_time) + safety_stock - stock_actual
     ```
   - [ ] Método 3: Consumo POS (últimos n días)
     ```
     Leer de inv_consumo_pos_det agrupado
     sugerido = proyección basada en consumo
     ```
   - [ ] Integración con POS (read-only desde `public.*`)
   - [ ] Validación: considerar órdenes pendientes
   - [ ] Cálculo de cobertura (días)

3. ✅ **UI de Pedidos Sugeridos** (4 días)
   - [ ] Botón "Generar Sugerencias"
   - [ ] Grilla editable con:
     - [ ] Ítem
     - [ ] Stock actual
     - [ ] Stock min/max
     - [ ] Consumo promedio
     - [ ] Qty sugerida (editable)
     - [ ] Cobertura (días)
     - [ ] Razón del cálculo (tooltip) ⭐
   - [ ] Filtros: sucursal, categoría, proveedor
   - [ ] Conversión 1-click: Sugerencia → Solicitud → Orden

4. ✅ **Simulador de Costo** (2 días)
   - [ ] "¿Qué pasa si ordeno X cantidad?"
   - [ ] Proyección de cobertura
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
    razon_calculo TEXT, -- "Min-Max: stock bajo mínimo"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Job Asíncrono**:
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
- ✅ Motor de replenishment funcionando
- ✅ Políticas de stock configurables
- ✅ UI de sugerencias con razón del cálculo
- ✅ PR: `feat/replenishment-engine-v7`

**Criterios de Aceptación**:
- [ ] "Generar Sugerencias" llena grilla con cantidades calculadas
- [ ] Usuario puede ver razón del cálculo (tooltip)
- [ ] Sugerencias se convierten a solicitud/orden
- [ ] Integración POS funciona (read-only)
- [ ] Tests de motor con múltiples métodos

---

#### **SPRINT 2.5: Reportes + Quick Wins** (1 semana)
**Objetivo**: Reportes exportables y quick wins de alto impacto

**Tareas**:

1. ✅ **Export de Reportes** (3 días) ⭐
   - [ ] Export CSV (todos los reportes)
   - [ ] Export PDF (reportes principales)
   - [ ] Usar Laravel Excel o TCPDF
   - [ ] Botón "Exportar" en cada reporte

2. ✅ **Drill-down en Dashboard** (2 días)
   - [ ] Click en KPI → detalle
   - [ ] Ejemplo: "Ventas $50k" → lista de tickets

3. ✅ **Búsqueda Global (Ctrl+K)** (2 días) ⭐
   - [ ] Alpine.js modal
   - [ ] Busca: ítems, recetas, órdenes, usuarios
   - [ ] Resultados agrupados por tipo
   - [ ] Navegación rápida

4. ✅ **Acciones en Lote** (1 día)
   - [ ] Checkbox en tablas
   - [ ] "Seleccionar todos"
   - [ ] Acciones: Eliminar, Activar/Desactivar, Export

**Entregables**:
- ✅ Exports CSV/PDF funcionando
- ✅ Búsqueda global Ctrl+K
- ✅ Acciones en lote en tablas
- ✅ PR: `feat/reports-quick-wins-v7`

**Criterios de Aceptación**:
- [ ] Usuario puede exportar cualquier reporte
- [ ] Búsqueda global responde < 500ms
- [ ] Acciones en lote funcionan en todas las tablas

---

#### **SPRINT 3: Recepciones Avanzadas + FEFO** (1-2 semanas)
**Objetivo**: Recepciones con FEFO y trazabilidad completa

**Tareas**:

1. ✅ **Auto-lookup por Código Proveedor** (2 días)
   - [ ] Input SKU proveedor → busca ítem
   - [ ] Suggest automático

2. ✅ **Conversión Automática con Tooltip** (2 días)
   - [ ] UOM compra → UOM base (automático)
   - [ ] Tooltip mostrando factor: "1 caja = 12 unidades"

3. ✅ **Adjuntos Múltiples** (3 días)
   - [ ] Drag & drop
   - [ ] Preview de imágenes
   - [ ] Storage en `storage/app/recepciones/`

4. ✅ **OCR para Lote/Caducidad** (4 días) - OPCIONAL
   - [ ] Tesseract.js o servicio cloud
   - [ ] Extraer fecha y lote de foto
   - [ ] Validación manual

5. ✅ **Plantillas de Recepción** (2 días)
   - [ ] Guardar recepción frecuente como plantilla
   - [ ] "Cargar plantilla" → pre-llena líneas

**Entregables**:
- ✅ Recepciones con adjuntos
- ✅ Conversión automática UOM
- ✅ Plantillas funcionando
- ✅ PR: `feat/advanced-receptions-v7`

---

#### **SPRINT 4: Recetas + Versionado + Costos Pro** (2 semanas)
**Objetivo**: Recetas con versionado y snapshots de costo

**Tareas**:

1. ✅ **Versionado de Recetas** (5 días) ⭐
   - [ ] `recipe_version` con número incremental
   - [ ] Al editar receta → crear nueva versión
   - [ ] Historial de versiones (UI)
   - [ ] Comparador de versiones (diff)

2. ✅ **Snapshot de Costo** (3 días)
   - [ ] Al cambiar costo de insumo → recalcular todas las recetas que lo usan
   - [ ] Job asíncrono: `RecalculateRecipeCosts`
   - [ ] Guardar en `recipe_cost_snapshot`
   - [ ] UI: historial de costos con gráfica

3. ✅ **Alertas de Costo** (2 días)
   - [ ] Umbral configurable (ej: +5%)
   - [ ] Notificación en dashboard
   - [ ] Email opcional

4. ✅ **Impacto de Costo** (3 días)
   - [ ] Simulador: "¿Qué pasa si sube 10% la leche?"
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
            
            // Alerta si cambió > 5%
            if ($this->costChangedMoreThan($recipe, 5)) {
                event(new CostAlertTriggered($recipe, $newCost));
            }
        }
    }
}
```

**Entregables**:
- ✅ Versionado de recetas
- ✅ Snapshots automáticos
- ✅ Alertas de costo funcionando
- ✅ PR: `feat/recipe-versioning-costs-v7`

**Criterios de Aceptación**:
- [ ] Al cambiar costo de insumo, recetas se recalculan automáticamente
- [ ] Usuario ve historial de costos con gráfica
- [ ] Alertas se generan cuando costo cambia > umbral
- [ ] Simulador de impacto funciona

---

#### **SPRINT 5: Transferencias + Discrepancias** (1 semana)
**Objetivo**: Transferencias con recepción y ajustes

**Tareas**:

1. ✅ **Flujo 3 Estados** (3 días)
   - [ ] Borrador → Despachada → Recibida
   - [ ] Al despachar: descuenta origen, crea "en tránsito"
   - [ ] Al recibir: abona destino por lote

2. ✅ **Confirmación Parcial** (2 días)
   - [ ] Recibir menos de lo enviado
   - [ ] Razón de discrepancia (dropdown)

3. ✅ **Botón "Recibir" en Destino** (2 días)
   - [ ] Sucursal destino puede ver transferencias pendientes
   - [ ] Click "Recibir" → posteo

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
- ✅ Transferencias con 3 estados
- ✅ Discrepancias manejadas
- ✅ PR: `feat/transfers-discrepancies-v7`

---

#### **SPRINT 6: Producción UI** (1-2 semanas)
**Objetivo**: UI operativa para órdenes de producción

**Tareas**:

1. ✅ **Planificación de OP** (4 días)
   - [ ] Por demanda (ventas POS)
   - [ ] Por stock objetivo
   - [ ] Por calendario (programadas)

2. ✅ **Consumo Teórico vs Real** (3 días)
   - [ ] Al crear OP: calcular consumo teórico
   - [ ] Al cerrar OP: registrar consumo real
   - [ ] Comparación con merma

3. ✅ **KPIs de Producción** (2 días)
   - [ ] Rendimiento (output/input)
   - [ ] Merma %
   - [ ] Costo por batch

4. ✅ **Cierre de OP** (3 días)
   - [ ] Validación: stock suficiente
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
- ✅ UI de producción operativa
- ✅ Cierre de OP con posteo
- ✅ KPIs de rendimiento
- ✅ PR: `feat/production-ui-v7`

---

#### **SPRINT 7: Mobile + Barcode** (1-2 semanas) - OPCIONAL
**Objetivo**: Experiencia mobile para operaciones

**Tareas**:

1. ✅ **UI Mobile-first para Conteos** (5 días)
   - [ ] Responsive design
   - [ ] Escaneo de código de barras (QuaggaJS)
   - [ ] Ajuste de qty con +/-

2. ✅ **Etiquetas/Barcode** (3 días)
   - [ ] Generación de códigos de barras
   - [ ] Impresión de etiquetas

3. ✅ **PWA** (3 días) - OPCIONAL
   - [ ] Service worker
   - [ ] Offline-first
   - [ ] Install prompt

**Entregables**:
- ✅ App mobile para conteos
- ✅ Barcode scanning
- ✅ PR: `feat/mobile-barcode-v7`

---

### 5.3 Resumen de Sprints

| Sprint | Duración | Prioridad | Impacto Negocio |
|--------|----------|-----------|-----------------|
| Sprint 0: Foundation | 1-2 sem | 🔥 CRÍTICO | Alto |
| Sprint 1: Inventario Base | 2 sem | 🔥 CRÍTICO | Alto |
| Sprint 2: Replenishment 🔥 | 2-3 sem | 🔥 CRÍTICO | MUY ALTO |
| Sprint 2.5: Reportes + Quick Wins | 1 sem | ⚠️ ALTO | Medio-Alto |
| Sprint 3: Recepciones Avanzadas | 1-2 sem | ⚠️ ALTO | Medio |
| Sprint 4: Recetas + Costos | 2 sem | ⚠️ ALTO | Alto |
| Sprint 5: Transferencias | 1 sem | ⚠️ MEDIO | Medio |
| Sprint 6: Producción UI | 1-2 sem | ⚠️ MEDIO | Medio (depende del negocio) |
| Sprint 7: Mobile + Barcode | 1-2 sem | 🟢 BAJO | Bajo-Medio |

**Total estimado**: 12-18 semanas (3-4.5 meses)

---

## 6. ANÁLISIS POR MÓDULO

*(continuará con análisis detallado de cada módulo, componentes específicos, wireframes, etc.)*

---

## 7. QUICK WINS (Bajo Esfuerzo, Alto Impacto)

### Semana 1:
1. ✅ **Validación inline** (2 días)
2. ✅ **Toasts con detalle** (1 día)
3. ✅ **Empty states** (1 día)
4. ✅ **Loading skeletons** (1 día)

### Semana 2:
1. ✅ **Export CSV** (2 días)
2. ✅ **Búsqueda global Ctrl+K** (2 días)
3. ✅ **Acciones en lote** (1 día)

### Semana 3-4:
1. ✅ **Wizard de alta item** (3 días)
2. ✅ **Auto-conversión UOM** (2 días)
3. ✅ **Snapshot de costos** (2 días)
4. ✅ **Políticas de stock UI** (2 días)

---

## 8. MÉTRICAS Y KPIs

### KPIs de Desarrollo

| Métrica | Objetivo | Actual | Gap |
|---------|----------|--------|-----|
| Cobertura de Tests | 80% | 30%? | +50% |
| Tiempo de Carga (p95) | < 2s | 3-5s? | -1-3s |
| Errores JS (producción) | < 5/día | ? | TBD |
| Uptime | 99.5% | ? | TBD |

### KPIs de Negocio

| Métrica | Objetivo | Método |
|---------|----------|--------|
| Reducción de ruptura de stock | -50% | Motor replenishment |
| Tiempo de conteo físico | -30% | Mobile app |
| Precisión de costos | +95% | Snapshots automáticos |
| Tiempo de cierre diario | -20 min | Automatización |

---

## 9. PLAN DE TESTING

### Testing Unitario (PHPUnit)
```php
tests/Unit/
├── Services/
│   ├── ReplenishmentEngineTest.php ⭐
│   ├── CostingServiceTest.php ⭐
│   └── RecipeServiceTest.php
└── Jobs/
    └── RecalculateRecipeCostsTest.php
```

### Testing de Integración
```php
tests/Feature/
├── Inventory/
│   ├── ItemCreationTest.php
│   ├── ReceptionPostingTest.php
│   └── TransferFlowTest.php
├── Purchasing/
│   └── ReplenishmentFlowTest.php ⭐
└── Recipes/
    └── CostRecalculationTest.php ⭐
```

### Testing E2E (Laravel Dusk)
```php
tests/Browser/
├── InventoryFlowTest.php
├── ReplenishmentFlowTest.php
└── ProductionFlowTest.php
```

---

## 10. ENTREGABLES

### Por Sprint:
1. ✅ **PR con código** (branch feat/*)
2. ✅ **Tests pasando** (PHPUnit + Dusk)
3. ✅ **Documentación** (README + inline)
4. ✅ **Screenshots/Video** (evidencia)
5. ✅ **Migration scripts** (si aplica)
6. ✅ **Seeder data** (datos de prueba)

### Finales:
1. ✅ **Manual de Usuario** (PDF)
2. ✅ **Guía de Desarrollo** (para mantenimiento)
3. ✅ **Documentación API** (Postman/Swagger)
4. ✅ **Videos de Capacitación** (por módulo)
5. ✅ **Plan de Rollback** (por si falla)

---

## 📞 CONTACTO Y PRÓXIMOS PASOS

### Decisiones Pendientes:

1. **¿Cuál es la prioridad #1 del negocio?**
   - Evitar rupturas → Priorizar Replenishment
   - Control de costos → Priorizar Recetas + Snapshots
   - Producción interna → Priorizar Producción UI

2. **¿Tienes equipo frontend o eres solo?**
   - Ajustar timeline según recursos

3. **¿Prefieres enfoque ágil (sprints) o MVP rápido?**
   - MVP = Sprint 0 + 1 + 2 (6-8 semanas)
   - Ágil = Todos los sprints (12-18 semanas)

4. **¿El negocio es más retail o producción?**
   - Retail → Priorizar Inventario + Compras
   - Producción → Priorizar Recetas + Producción

---

**Fecha de Creación**: 31 de octubre de 2025, 02:30  
**Versión**: v7.0 Enterprise  
**Estado**: 🟢 LISTO PARA EJECUTAR

**Base de Datos**: ✅ Enterprise-grade completada (31 oct 00:40)  
**Frontend**: ⏳ Pendiente de implementación (este plan)

---

*Documento creado en base a:*
- ✅ Auditoría UI/UX (AuditoriaGPT.txt)
- ✅ MASTER_ROADMAP_V6.md
- ✅ PERMISSIONS_MATRIX_V6.md
- ✅ UI_GATING_MAP_V6.md
- ✅ PERMISSIONS_SEEDER_V6.php
- ✅ SEED_PLANTILLAS_V6.sql
- ✅ Análisis experto (Claude AI)
- ✅ Base de Datos Enterprise v7.0 (recién completada)

**¡Sistema listo para transformarse en ERP de clase mundial! 🚀**
