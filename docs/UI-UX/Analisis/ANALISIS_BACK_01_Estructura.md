# 📊 ANÁLISIS BACKEND - PARTE 1: ESTRUCTURA ACTUAL

**Fecha:** 2025-10-31  
**Proyecto:** Terrena ERP/POS  
**Versión:** Laravel 10.x  
**Base:** FloreantPOS (legacy PostgreSQL 9.5)

---

## 🏗️ ARQUITECTURA ACTUAL

### Stack Tecnológico
- **Framework:** Laravel 10.x
- **Base de Datos:** PostgreSQL 9.5 (schema: selemti)
- **Frontend:** Livewire + Alpine.js + Tailwind CSS + Bootstrap
- **Build:** Vite
- **API:** RESTful (routes/api.php)
- **Autenticación:** Laravel Sanctum + Session-based

---

## 📁 ESTRUCTURA DE CARPETAS

### Controllers (48 archivos)
```
app/Http/Controllers/
├── Api/
│   ├── Caja/              # 9 controladores - Sistema de cajas
│   ├── Inventory/         # 5 controladores - Inventario
│   ├── Unidades/          # 2 controladores - Unidades de medida
│   ├── AlertsController.php
│   ├── CatalogsController.php
│   ├── MeController.php
│   ├── PeopleController.php
│   └── ReportsController.php
├── Audit/                 # 3 controladores - Auditoría
├── Auth/                  # 11 controladores - Autenticación
├── Catalogs/              # 1 controlador
├── Inventory/             # 2 controladores
├── Pos/                   # 2 controladores
├── Production/            # 1 controlador
├── Purchasing/            # 3 controladores
└── Reports/               # 1 controlador
```

### Services (29 archivos)
```
app/Services/
├── Alerts/                # AlertEngine.php
├── Audit/                 # 2 servicios
├── Cash/                  # CashFundService.php
├── Costing/               # RecipeCostingService.php
├── Inventory/             # 8 servicios (core del sistema)
├── Menu/                  # MenuEngineeringService.php
├── Operations/            # 2 servicios (DailyClose, PosConsumption)
├── Pos/                   # 8 archivos (DTOs + Repositories + Sync)
├── Production/            # ProductionService.php
├── Purchasing/            # 2 servicios
├── Recetas/               # RecalcularCostosRecetasService.php
├── Replenishment/         # ReplenishmentService.php
└── Reporting/             # ReportService.php
```

### Models (24 modelos Laravel)
```
app/Models/
├── Almacen.php
├── AuditLog.php
├── CashFund.php
├── CashFundArqueo.php
├── CashFundMovement.php
├── CashFundMovementAuditLog.php
├── CatUnidad.php
├── Insumo.php
├── InventoryCount.php
├── InventoryCountLine.php
├── Item.php
├── PosMap.php
├── ProductionOrder.php
├── PurchaseDocument.php
├── PurchaseOrder.php
├── PurchaseOrderLine.php
├── PurchaseRequest.php
├── PurchaseRequestLine.php
├── ReplenishmentSuggestion.php
├── StockPolicy.php
├── Sucursal.php
├── User.php
├── VendorQuote.php
└── VendorQuoteLine.php
```

**⚠️ NOTA:** Se trabaja con ~150 tablas legacy de FloreantPOS (sin modelos Eloquent)

### Migraciones
- **Total:** 69 migraciones
- **Estado:** Base normalizada (Phases 1-2 completadas)
- **Últimas:** Consolidación usuarios/roles, sucursales/almacenes, items, recetas

---

## 🔗 RUTAS PRINCIPALES

### API Routes (`routes/api.php`)
```php
/api/reports/*              # KPIs, ventas, dashboards
/api/caja/*                 # Sistema de cajas POS
/api/unidades/*             # Unidades y conversiones
/api/inventory/*            # Items, precios, stock, vendors
/api/catalogs/*             # Catálogos generales
/api/production/*           # Órdenes de producción
/api/purchasing/*           # Sugerencias, recepciones, devoluciones
/api/alerts/*               # Sistema de alertas
/api/me                     # Usuario actual
```

### Web Routes (`routes/web.php`)
```php
/__probe                    # Diagnóstico
/dashboard                  # Dashboard principal
/catalogs/*                 # Unidades, almacenes, proveedores, sucursales
/inventory/*                # Recepciones, lotes, insumos, items
/purchasing/*               # Sugerencias de compra
/production/*               # Órdenes de producción
/reports/*                  # Reportes web
/audit/*                    # Logs de auditoría
/profile/*                  # Perfil de usuario
```

---

## 🧩 COMPONENTES LIVEWIRE

### Catálogos (6 componentes)
- UnidadesIndex
- UomConversionIndex
- AlmacenesIndex
- ProveedoresIndex
- SucursalesIndex
- StockPolicyIndex

### Inventario (7 componentes)
- ReceptionsIndex
- ReceptionCreate
- ReceptionDetail
- LotsIndex
- ItemsManage
- InsumoCreate
- TransfersIndex

### Compras (2 componentes)
- PurchaseSuggestionsIndex
- PurchaseRequestsIndex

### Producción (2 componentes)
- ProductionOrdersIndex
- ProductionOrderCreate

### Reportes (1 componente)
- ReportsIndex

---

## 🗄️ BASE DE DATOS

### Estado Actual Post-Normalización
```
✅ Phase 1: Fundamentos           100% completado
✅ Phase 2.1: Usuarios/Roles      100% completado
✅ Phase 2.2: Sucursales/Almacenes 100% completado
✅ Phase 2.3: Items               100% completado
✅ Phase 2.4: Recetas             100% completado
✅ Phase 3: Constraints/Indexes    100% completado
✅ Phase 4: Performance           100% completado
✅ Phase 5: Enterprise Features   100% completado
```

### Tablas Consolidadas
- `users` (consolidada de `usuario` legacy)
- `roles` (consolidada de `rol` legacy)
- `sucursales` (consolidada)
- `almacenes` (consolidada)
- `items` (consolidada - catálogo maestro)
- `recetas` (consolidada - multi-nivel)

### Vistas de Compatibilidad
- `v_usuario` → mapea a `users`
- `v_rol` → mapea a `roles`
- `v_sucursal_legacy` → compatibilidad FloreantPOS
- `v_item_legacy` → compatibilidad FloreantPOS

---

## 📦 DEPENDENCIAS PRINCIPALES

### Backend (composer.json)
```json
{
  "laravel/framework": "^10.0",
  "livewire/livewire": "^3.0",
  "laravel/sanctum": "^3.0",
  "spatie/laravel-permission": "posible",
  "barryvdh/laravel-debugbar": "dev"
}
```

### Frontend (package.json)
```json
{
  "@alpinejs/focus": "^3.x",
  "@tailwindcss/forms": "^0.5",
  "bootstrap": "^5.3",
  "chart.js": "^4.x",
  "select2": "^4.x"
}
```

---

## 🎯 PATRONES DE DISEÑO IMPLEMENTADOS

### Repository Pattern
- `app/Services/Pos/Repositories/*`
- Abstracción de consultas a tablas legacy

### Service Layer
- Lógica de negocio en `app/Services/*`
- Separación clara de responsabilidades

### DTO (Data Transfer Objects)
- `app/Services/Pos/DTO/*`
- PosConsumptionResult, PosConsumptionDiagnostics

### Observer Pattern (implícito)
- Livewire components reactivos
- Alpine.js para interactividad

### Factory Pattern
- Laravel Factories para testing/seeding

---

## ⚙️ CARACTERÍSTICAS TÉCNICAS

### Autenticación & Autorización
- ✅ Laravel Breeze (base)
- ✅ Sanctum API tokens
- ✅ Session-based auth
- ⚠️ Permisos granulares (parcial - necesita Spatie)

### API
- ✅ RESTful endpoints
- ✅ JSON responses
- ⚠️ Versionado (no implementado)
- ⚠️ Rate limiting (básico)
- ⚠️ API Documentation (falta)

### Seguridad
- ✅ CSRF protection
- ✅ SQL injection protection (Eloquent)
- ✅ XSS protection (Blade escaping)
- ✅ Audit logging (implementado)
- ⚠️ 2FA (no implementado)

### Performance
- ✅ Eager loading (relaciones)
- ✅ Query optimization (algunos casos)
- ✅ Índices en BD (Phase 4 completada)
- ⚠️ Caching (básico - necesita Redis)
- ⚠️ Queue jobs (no implementado para todos los casos)

---

## 📊 MÉTRICAS DE CÓDIGO

```
Controladores:    48 archivos
Services:         29 archivos
Models:           24 modelos Laravel
Migraciones:      69 archivos
Componentes:      18 Livewire
Rutas API:        ~50 endpoints
Rutas Web:        ~40 rutas
Tablas DB:        ~150 (legacy) + 30 nuevas
```

---

## 🔍 OBSERVACIONES INICIALES

### ✅ Fortalezas
1. **Arquitectura limpia** - Separación Controllers/Services
2. **Normalización avanzada** - BD optimizada (Phases 1-5)
3. **Auditoría robusta** - Tracking de cambios implementado
4. **Modularidad** - Componentes Livewire reutilizables
5. **API funcional** - Endpoints RESTful operativos

### ⚠️ Áreas de Mejora Identificadas
1. **Documentación API** - Falta Swagger/OpenAPI
2. **Testing** - Coverage bajo (necesita validación)
3. **Caché** - No hay estrategia Redis implementada
4. **Jobs/Queues** - Procesos síncronos que deberían ser async
5. **Middleware personalizado** - Necesario para validaciones complejas
6. **Versionado API** - No hay estrategia de versiones

---

**Siguiente:** [ANALISIS_BACK_02_Funcionalidades.md](./ANALISIS_BACK_02_Funcionalidades.md)
