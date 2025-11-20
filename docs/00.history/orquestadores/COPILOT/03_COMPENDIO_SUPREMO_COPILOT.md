# COMPENDIO SUPREMO FUSIÓN - TERRENA v2.0
## Orquestador: COPILOT
**Fecha:** 2025-11-14  
**Basado en:** Fase 1 Auditoría + Extracción BD selemti

---

## ÍNDICE EJECUTIVO

Este documento fusiona TODOS los hallazgos de la auditoría Fase 1 realizada el 2025-11-14, consolidando:
- Documentación (docs/ + docs/V4.0 + D:\Tavo\2025\UX\)
- Código (app/, routes/, resources/)
- Base de datos (selemti: 185 tablas, 38 vistas, 37 funciones)
- Arquitectura y dependencias

**Propósito:** Fuente única de verdad para desarrollo post-auditoría.

---

## PARTE 1: ARQUITECTURA CONFIRMADA

### Stack Tecnológico Real
```yaml
Backend:
  Framework: Laravel 10.x
  Lenguaje: PHP 8.3
  Base de datos: PostgreSQL 14+
  Esquema: selemti
  ORM: Eloquent

Frontend:
  Motor: Livewire 3.x
  JS: Alpine.js
  CSS: Tailwind CSS (+ Bootstrap legacy en migración)
  Build: Vite

Infraestructura:
  Servidor web: Apache 2.4
  Colas: Redis
  Cache: Redis
  Storage: Local (público + privado)
  
Seguridad:
  Autenticación: Laravel Breeze
  Autorización: Spatie Laravel Permission
  API: Sanctum tokens

Desarrollo:
  WSL IP: 172.24.240.1 (PostgreSQL desde host)
  Deployment: Manual (sin CI/CD configurado)
```

### Estructura Proyecto Confirmada
```
app/
├── Http/Controllers/          ← REST API + Web
│   ├── Api/                   ← Endpoints /api/*
│   │   ├── Caja/             ← Precorte, postcorte, sesiones
│   │   ├── Inventory/        ← Items, stock, transfers
│   │   └── Unidades/         ← UOM conversiones
│   ├── Reports/              ← Reportes Jasper-like
│   ├── Purchasing/           ← Sugerencias, recepciones
│   └── Production/           ← Producción API
├── Livewire/                 ← Componentes UI
│   ├── CashFund/             ← 6 componentes caja
│   ├── Inventory/            ← 8 componentes inventario
│   ├── InventoryCount/       ← 5 componentes conteos
│   ├── Recipes/              ← 2 componentes recetas
│   ├── Purchasing/           ← 6 componentes compras
│   ├── Pos/                  ← 1 componente mapeo
│   ├── Transfers/            ← 2 componentes transferencias
│   ├── Replenishment/        ← 1 componente (vacío)
│   ├── Reports/              ← 2 componentes reportes
│   ├── Catalogs/             ← 6 componentes catálogos
│   └── People/               ← 1 componente usuarios
├── Models/                   ← Eloquent models
│   ├── Inv/                  ← Item, InventoryBatch
│   ├── Rec/                  ← Receta, RecetaVersion, RecetaDetalle, RecetaShadow
│   └── Purchasing/           ← PurchaseOrder, PurchaseRequest
├── Services/                 ← Lógica negocio
│   ├── Inventory/            ← Reception, Transfer, Production, InventoryCount
│   ├── Costing/              ← RecipeCostingService
│   ├── Recetas/              ← RecalcularCostosRecetasService
│   ├── Pos/                  ← PosConsumptionService
│   ├── Purchasing/           ← ReceivingService, PurchasingService
│   └── Cash/                 ← Servicios caja chica
└── Actions/, Exports/, Helpers/, Policies/, Providers/, Support/, Traits/

routes/
├── web.php                   ← Livewire routes
└── api.php                   ← REST API routes

resources/
├── views/
│   ├── livewire/             ← Vistas Livewire por módulo
│   ├── components/           ← Componentes Blade reutilizables
│   ├── layouts/              ← terrena, app, guest
│   ├── inventory/, recipes/, reports/, caja/, pos/, transfers/
│   └── dashboard.blade.php
└── js/, css/                 ← Assets Vite

database/
├── migrations/               ← Migraciones Laravel (algunas)
└── seeders/                  ← Seeders básicos

docs/
├── V4.0/                     ← Documentación oficial
│   ├── Arquitectura/
│   ├── Frontend/
│   ├── Guia/
│   ├── Inventario/
│   ├── Recetas/
│   ├── Produccion/
│   ├── POS/
│   ├── Finanzas/
│   ├── Purchasing/
│   ├── Reports/
│   └── Caja/
└── 00.history/               ← Documentación histórica
```

---

## PARTE 2: BASE DE DATOS - INVENTARIO COMPLETO

### Estadísticas Globales
- **Total objetos:** 185 (147 tablas + 38 vistas)
- **Funciones:** 37 PL/pgSQL
- **Triggers:** 22 activos
- **Foreign Keys:** 134 relaciones
- **Estado:** BD recién desplegada (poca data operativa)

### Tablas Core por Módulo

#### INVENTARIO (15 tablas)
```sql
-- Catálogo
items                          -- 6 registros (catálogo base)
item_categories                -- Categorías ítems
item_vendor                    -- Proveedores por ítem
item_vendor_prices             -- Precios históricos proveedor

-- Lotes y stock
inventory_batch                -- 0 registros (lotes)
inventory_snapshot             -- Snapshots históricos
cost_layer                     -- Capas de costo

-- Movimientos
mov_inv                        -- 0 registros (kardex)
lote                           -- Lotes legacy

-- Recepciones
recepcion_cab                  -- Cabecera recepciones
recepcion_det                  -- Detalle recepciones

-- Transferencias
transfer_cab, transfer_det, traspaso_cab, traspaso_det

-- Conteos
inventory_counts               -- 0 registros
inventory_count_lines          -- 0 registros

-- Mermas
inventory_wastes               -- Mermas/desperdicios
perdida_log                    -- Log pérdidas
merma                          -- Mermas legacy
```

#### RECETAS (10 tablas)
```sql
receta_cab                     -- 0 registros (cabecera)
receta_det                     -- 0 registros (detalle)
receta_version                 -- 0 registros (versionado)
receta_shadow                  -- 0 registros (inferidas POS)

hist_cost_receta               -- Histórico costos
historial_costos_receta        -- Histórico costos v2

menu_engineering_snapshots     -- Snapshots ingeniería menú
menu_items                     -- Items menú POS
menu_item_sync_map             -- Mapeo sync POS

modificadores_pos              -- Modificadores
```

#### UOM (5 tablas + 4 vistas)
```sql
-- Tablas
cat_unidades                   -- Catálogo unidades
cat_uom_conversion             -- Conversiones
conversiones_unidad_legacy     -- Legacy
unidades_medida                -- Unidades legacy
insumo_presentacion            -- Presentaciones insumo

-- Vistas
conversiones_unidad            -- Vista unificada
unidad_medida                  -- Vista singular
unidades_medida                -- Vista plural
uom_conversion                 -- Vista conversiones
```

#### PRODUCCIÓN (7 tablas)
```sql
production_orders              -- 0 registros (órdenes)
production_order_inputs        -- Inputs órdenes
production_order_outputs       -- Outputs órdenes

op_produccion_cab              -- 0 registros (órdenes legacy)
op_cab, op_insumo, op_yield    -- Órdenes legacy

prod_cab, prod_det             -- Producción legacy
```

#### COMPRAS (6 tablas)
```sql
purchase_requests              -- 0 registros (solicitudes)
purchase_request_lines         -- Líneas solicitudes
purchase_orders                -- 0 registros (órdenes compra)
purchase_order_lines           -- Líneas PO
purchase_documents             -- Documentos compra

inv_stock_policy               -- 0 registros (políticas stock)
```

#### POS & CONSUMOS (10 tablas)
```sql
pos_map                        -- 0 registros (mapeo POS-receta)
pos_modifiers_map              -- Mapeo modificadores

inv_consumo_pos                -- Consumo por ticket
inv_consumo_pos_det            -- Detalle consumo
inv_consumo_pos_log            -- Log cambios

pos_reprocess_log              -- Log reprocesos
pos_reverse_log                -- Log reversiones
pos_sync_batches               -- Batches sync
pos_sync_logs                  -- Logs sync

ticket_venta_cab, ticket_venta_det, ticket_det_consumo  -- Ventas POS
```

#### CAJA & FINANZAS (15 tablas)
```sql
-- Fondos caja chica
cash_funds                     -- 1 registro (fondo activo)
cash_fund_movements            -- 0 registros
cash_fund_arqueos              -- Arqueos

caja_fondo                     -- Legacy
caja_fondo_mov, caja_fondo_adj, caja_fondo_arqueo, caja_fondo_usuario

-- Cortes
precorte                       -- 33 registros
precorte_efectivo              -- Efectivo precorte
precorte_otros                 -- Otros medios
postcorte                      -- 27 registros

sesion_cajon                   -- 132 registros (sesiones)
param_sucursal                 -- Parámetros sucursal

conciliacion                   -- Conciliación
```

#### CATÁLOGOS (9 tablas)
```sql
cat_almacenes                  -- Almacenes
cat_proveedores                -- Proveedores
cat_sucursales                 -- Sucursales

almacen                        -- Almacenes v2
bodega                         -- Bodegas
sucursal                       -- Sucursales v2
proveedor                      -- Proveedores v2

formas_pago                    -- Formas de pago
labor_roles                    -- Roles labor
overhead_definitions           -- Definiciones overhead
```

#### SEGURIDAD & AUDITORÍA (8 tablas)
```sql
users                          -- Usuarios
permissions                    -- Permisos Spatie
roles                          -- Roles Spatie
model_has_permissions          -- Permisos asignados
model_has_roles                -- Roles asignados

audit_log                      -- Log auditoría específica
audit_log_global               -- Log auditoría global
auditoria                      -- Auditoría legacy
```

#### SISTEMA (9 tablas)
```sql
migrations                     -- Migraciones Laravel
failed_jobs                    -- Jobs fallidos
jobs                           -- Cola jobs
job_batches                    -- Batches jobs
job_recalc_queue               -- Cola recálculos

password_reset_tokens          -- Reset passwords
personal_access_tokens         -- Tokens Sanctum

cache, cache_locks             -- Cache Redis
```

#### ALERTAS (2 tablas)
```sql
alert_rules                    -- Reglas alertas
alert_events                   -- Eventos alertas
alertas_cortes                 -- Alertas cortes
```

#### BACKUPS (3 tablas)
```sql
backup_tickets_cierre_masivo_20251112_112653
backup_tickets_cierre_masivo_20251112_121131
backup_tickets_cierre_masivo_20251112_121211
```

### Vistas Materializadas (38 vistas)

#### Dashboards & KPIs (13 vistas)
```sql
vw_dashboard_formas_pago              -- Formas pago dashboard
vw_dashboard_ordenes                  -- Órdenes dashboard
vw_dashboard_resumen_sucursal         -- KPIs sucursal
vw_dashboard_resumen_terminal         -- KPIs terminal
vw_dashboard_ticket_base              -- Base tickets
vw_dashboard_ventas_categorias        -- Ventas por categoría
vw_dashboard_ventas_hora              -- Ventas por hora
vw_dashboard_ventas_productos         -- Ventas por producto
vw_ticket_promedio_sucursal_dia       -- Ticket promedio
vw_ventas_por_hora                    -- Ventas horarias
vw_fast_tickets                       -- Tickets rápidos
vw_fast_tx                            -- Transacciones rápidas
vw_pagos_por_terminal_dia             -- Pagos terminal
```

#### Sesiones & Cortes (4 vistas)
```sql
vw_sesion_dpr                         -- Detalles sesión
vw_sesion_descuentos                  -- Descuentos sesión
vw_sesion_reembolsos_efectivo         -- Reembolsos
vw_sesion_retiros                     -- Retiros
vw_sesion_ventas                      -- Ventas sesión
```

#### Conciliación (4 vistas)
```sql
vw_conciliacion_efectivo              -- Conciliación efectivo
vw_conciliacion_sesion                -- Conciliación sesión
vw_conciliacion_tarjetas              -- Conciliación tarjetas
vw_resumen_conciliacion_terminal_dia  -- Resumen conciliación
```

#### Inventario (6 vistas)
```sql
vw_kardex                             -- Kardex movimientos
vw_stock_por_lote_fefo                -- Stock FEFO
vw_item_last_price                    -- Último precio ítem
vw_item_last_price_pref               -- Precio preferente
vw_stock_actual                       -- Stock actual (v_stock_actual)
vw_stock_brechas                      -- Brechas stock (v_stock_brechas)
```

#### Recetas & Producción (3 vistas)
```sql
vw_ingenieria_menu_completa           -- Ingeniería menú completa (v_ingenieria_menu_completa)
vw_pos_map_resuelto                   -- Mapeo POS resuelto
vw_merma_por_item                     -- Mermas por ítem (v_merma_por_item)
```

#### Replenishment (1 vista)
```sql
vw_replenishment_dashboard            -- Dashboard sugerencias compra
```

#### Anomalías (1 vista)
```sql
vw_movimientos_anomalos               -- Movimientos anómalos
```

#### Catálogos Compatibilidad (6 vistas)
```sql
v_almacen                             -- Vista almacén
v_bodega                              -- Vista bodega
v_cat_unidades_compat                 -- Unidades compatibilidad
v_insumo                              -- Vista insumo
v_lote                                -- Vista lote
v_receta                              -- Vista receta
v_receta_insumo                       -- Receta-insumo
v_rol                                 -- Vista rol
v_sucursal                            -- Vista sucursal
v_unidad_medida_singular_compat       -- Unidad singular compat
v_usuario                             -- Vista usuario
v_items_con_uom                       -- Items con UOM
```

### Funciones PL/pgSQL (37 funciones)

#### Triggers (10 funciones)
```sql
audit_trigger_func()                  -- Auditoría genérica
fn_after_price_insert_alert()         -- Alerta cambio precio
fn_assign_item_code()                 -- Asignar código ítem
fn_dah_after_insert()                 -- After insert histórico
fn_dah_after_insert_refuerzo()        -- Refuerzo histórico
fn_ivp_upsert_close_prev()            -- Cerrar precio previo
fn_gen_cat_codigo()                   -- Generar código catálogo
set_timestamp_ipp()                   -- Timestamp insumo-proveedor
tg_invshot_autofill()                 -- Autofill snapshot
update_updated_at_column()            -- Actualizar updated_at
```

#### Cortes & Caja (7 funciones)
```sql
fn_generar_postcorte()                -- Generar postcorte (BIGINT)
fn_postcorte_after_insert()           -- After insert postcorte
fn_precorte_after_insert()            -- After insert precorte
fn_precorte_after_update_aprobado()   -- After update precorte aprobado
fn_precorte_efectivo_bi()             -- Before insert/update precorte efectivo
fn_terminal_bu_snapshot_cierre()      -- Snapshot cierre terminal
fn_fondo_actual()                     -- Calcular fondo actual (NUMERIC)
fn_reparar_sesion_apertura()          -- Reparar sesión (TEXT)
```

#### Consumos POS (4 funciones)
```sql
fn_confirmar_consumo_ticket()         -- Confirmar consumo (VOID)
fn_expandir_consumo_ticket()          -- Expandir consumo (VOID)
fn_reversar_consumo_ticket()          -- Reversar consumo (VOID)
trg_ticket_inventory_consumption()    -- Trigger consumo automático
```

#### Recetas & Costeo (6 funciones)
```sql
fn_recipe_cost_at()                   -- Costo receta histórico (RECORD)
fn_recipes_using_item()               -- Recetas que usan ítem (BIGINT)
recalcular_costos_periodo()           -- Recalcular periodo (INTEGER)
reprocesar_costos_historicos()        -- Reprocesar históricos (INTEGER)
sp_snapshot_recipe_cost()             -- Snapshot costo receta (VOID)
inferir_recetas_de_ventas()           -- Inferir recetas shadow (INTEGER)
```

#### Producción (2 funciones)
```sql
cerrar_lote_preparado()               -- Cerrar lote (BIGINT)
registrar_consumo_porcionado()        -- Registrar consumo (INTEGER)
```

#### Formas de Pago (2 funciones)
```sql
fn_normalizar_forma_pago()            -- Normalizar nombre (TEXT)
fn_tx_after_insert_forma_pago()       -- After insert transacción
```

#### Utilities (6 funciones)
```sql
fn_item_unit_cost_at()                -- Costo unitario histórico (NUMERIC)
fn_uom_factor()                       -- Factor conversión UOM (NUMERIC)
fn_slug()                             -- Generar slug (TEXT)
refresh_materialized_views()          -- Refrescar vistas (VOID)
ingesta_ticket()                      -- Ingestar ticket (VOID)
```

### Triggers Activos (22 triggers)

#### Items & Proveedores
```sql
trg_items_assign_code                 -- Before INSERT items
trg_ivp_after_insert                  -- After INSERT item_vendor_prices
trg_ivp_close_prev                    -- Before INSERT item_vendor_prices
trg_ipp_set_timestamp                 -- Before UPDATE insumo_proveedor_presentacion
```

#### Inventario
```sql
trg_invshot_biur                      -- Before INSERT/UPDATE inventory_snapshot
```

#### Categorías
```sql
trg_item_categories_autocode          -- Before INSERT item_categories
```

#### Cortes & Caja
```sql
trg_postcorte_after_insert            -- After INSERT postcorte
trg_precorte_after_insert             -- After INSERT precorte
trg_precorte_after_update_aprobado    -- After UPDATE precorte (aprobado)
trg_precorte_efectivo_bi              -- Before INSERT/UPDATE precorte_efectivo
```

#### Recepciones & Transferencias
```sql
update_recepcion_cab_updated_at       -- Before UPDATE recepcion_cab
update_recepcion_det_updated_at       -- Before UPDATE recepcion_det
update_traspaso_cab_updated_at        -- Before UPDATE traspaso_cab
update_traspaso_det_updated_at        -- Before UPDATE traspaso_det
```

#### Producción & Mermas
```sql
update_op_cab_updated_at              -- Before UPDATE op_cab
update_op_insumo_updated_at           -- Before UPDATE op_insumo
update_merma_updated_at               -- Before UPDATE merma
```

#### Costos
```sql
update_hist_cost_insumo_updated_at    -- Before UPDATE hist_cost_insumo
update_insumo_presentacion_updated_at -- Before UPDATE insumo_presentacion
update_insumo_proveedor_presentacion_updated_at -- Before UPDATE insumo_proveedor_presentacion
```

### Foreign Keys Críticas (134 relaciones)

**Ejemplos clave:**
```sql
-- Inventario
items → item_categories
inventory_batch → items
mov_inv → items, almacen
inventory_wastes → items

-- Recetas
receta_det → receta_cab (subrecetas)
receta_det → items (ingredientes)
receta_version → receta_cab

-- Compras
purchase_request_lines → purchase_requests
purchase_order_lines → purchase_orders
purchase_orders → proveedor

-- POS
pos_map → items, receta_cab
inv_consumo_pos_det → items

-- Caja
cash_fund_movements → cash_funds
precorte → sesion_cajon
postcorte → precorte

-- Permisos
model_has_permissions → permissions, users
model_has_roles → roles, users
```

---

## PARTE 3: RUTAS CONFIRMADAS

### Web Routes (routes/web.php)
```php
// Home & Dashboard
GET  /                        → redirect login/dashboard
GET  /dashboard               → dashboard (auth)

// Inventory
GET  /inventory/*             → Livewire components

// Recipes
GET  /recipes/*               → Livewire components

// Purchasing
GET  /purchasing/orders/*     → Livewire components
GET  /purchasing/requests/*   → Livewire components

// Cash Fund
GET  /cash-fund/*             → Livewire components

// Caja (Histórico Cortes)
GET  /caja/*                  → Vistas cortes

// Reports
GET  /reports/*               → Livewire/Controllers

// Catalogs
GET  /catalogs/*              → Livewire components

// Admin
GET  /admin/*                 → Administración

// Auth (Breeze)
GET|POST /login, /logout, /register, /password/*
```

### API Routes (routes/api.php)
```php
// Health
GET  /ping                    → {ok: true}
GET  /health                  → HealthController

// Auth (sin middleware para dev)
POST /auth/login              → AuthController@login

// Reports & Dashboards
GET  /reports/kpis/sucursal   → KPIs sucursal
GET  /reports/kpis/terminal   → KPIs terminal
GET  /reports/ventas/*        → Ventas endpoints
GET  /reports/stock/val       → Stock valorizado
GET  /reports/consumo/vr      → Consumo vs movimientos
GET  /reports/anomalias       → Movimientos anómalos
GET  /reports/purchasing/late-po
GET  /reports/inventory/over-tolerance
GET  /reports/inventory/top-urgent

// Reports Jasper-like
GET  /reports/sales/detail    → SalesDetailController
GET  /reports/sales/summary   → SalesSummaryController
GET  /reports/sales/balance   → SalesBalanceController
GET  /reports/sales/exceptions
GET  /reports/menu/usage
GET  /reports/sales/journal   (alias: /reports/journal)

// Caja
POST /caja/login              → AuthController@login
GET  /caja/sesiones/*         → SesionesController
GET  /caja/postcorte/*        → PostcorteController
GET  /caja/precorte/*         → PrecorteController
GET  /caja/conciliacion/*     → ConciliacionController
GET  /caja/formas-pago        → FormasPagoController
GET  /caja/alertas            → AlertasController

// Inventory
GET  /inventory/items/*       → ItemController
GET  /inventory/stock/*       → StockController
GET  /inventory/prices/*      → PriceController
GET  /inventory/transfers/*   → TransferApiController

// Recipes
GET  /recipes/*               → RecipeCostController (sin middleware)

// Unidades
GET  /unidades/*              → UnidadController
GET  /unidades/conversiones/* → ConversionController

// Catalogs
GET  /catalogs/*              → CatalogsController

// Purchasing
GET  /purchasing/suggestions/* → PurchaseSuggestionController (no implementado)
GET  /purchasing/receiving/*  → ReceivingController
GET  /purchasing/returns/*    → ReturnController

// Production
GET  /production/batch/*      → ProductionController

// Vendors
GET  /vendors/*               → VendorController

// Alerts
GET  /alerts/*                → AlertsController

// Me
GET  /me                      → MeController

// ⚠️ FALTANTE: /api/pos/recipe-cost (RecipeCostController no expuesto)
```

---

## PARTE 4: COMPONENTES LIVEWIRE COMPLETOS

### CashFund (6 componentes)
```php
App\Livewire\CashFund\Index          // Listado fondos
App\Livewire\CashFund\Open           // Apertura fondo
App\Livewire\CashFund\Detail         // Detalle fondo
App\Livewire\CashFund\Movements      // Movimientos
App\Livewire\CashFund\Arqueo         // Arqueos
App\Livewire\CashFund\Approvals      // Aprobaciones
```

### Inventory (8 componentes)
```php
App\Livewire\Inventory\ItemsManage         // Gestión ítems
App\Livewire\Inventory\InsumoCreate        // Alta ítem
App\Livewire\Inventory\ReceptionsIndex     // Listado recepciones
App\Livewire\Inventory\ReceptionCreate     // Crear recepción
App\Livewire\Inventory\ReceptionDetail     // Detalle recepción
App\Livewire\Inventory\LotsIndex           // Listado lotes
App\Livewire\Inventory\PhysicalCounts      // Conteos físicos
App\Livewire\Inventory\AlertsList          // Alertas inventario
```

### InventoryCount (5 componentes)
```php
App\Livewire\InventoryCount\Index          // Listado conteos
App\Livewire\InventoryCount\Create         // Crear conteo
App\Livewire\InventoryCount\Capture        // Captura conteo
App\Livewire\InventoryCount\Review         // Revisar conteo
App\Livewire\InventoryCount\Detail         // Detalle conteo
```

### Recipes (2 componentes)
```php
App\Livewire\Recipes\RecipesIndex          // Listado recetas
App\Livewire\Recipes\RecipeEditor          // Editor receta
```

### Purchasing (6 componentes)
```php
App\Livewire\Purchasing\Requests\Index     // Listado solicitudes
App\Livewire\Purchasing\Requests\Create    // Crear solicitud
App\Livewire\Purchasing\Requests\Detail    // Detalle solicitud
App\Livewire\Purchasing\Orders\Index       // Listado POs
App\Livewire\Purchasing\Orders\Detail      // Detalle PO
```

### Pos (1 componente)
```php
App\Livewire\Pos\PosMap                    // Mapeo POS-Recetas
```

### Transfers (2 componentes)
```php
App\Livewire\Transfers\Create              // Crear transferencia
App\Livewire\Transfers\Index               // Listado transferencias (no confirmado)
```

### Replenishment (1 componente vacío)
```php
App\Livewire\Replenishment\Dashboard       // ⚠️ VACÍO - No implementado
```

### Reports (2 componentes)
```php
App\Livewire\Reports\Dashboard             // Dashboard reportes
App\Livewire\Reports\DrillDown             // Drill-down reportes
```

### Catalogs (6 componentes)
```php
App\Livewire\Catalogs\AlmacenesIndex       // Almacenes
App\Livewire\Catalogs\ProveedoresIndex     // Proveedores
App\Livewire\Catalogs\StockPolicyIndex     // Políticas stock
App\Livewire\Catalogs\SucursalesIndex      // Sucursales
App\Livewire\Catalogs\UnidadesIndex        // Unidades medida
App\Livewire\Catalogs\UomConversionIndex   // Conversiones UOM
```

### People (1 componente)
```php
App\Livewire\People\UsersIndex             // Gestión usuarios
```

### KDS (1 componente)
```php
App\Livewire\Kds\Board                     // ⚠️ Kitchen Display (no confirmado uso)
```

**Total Livewire:** 41 componentes

---

## PARTE 5: SERVICIOS BACKEND

### Inventory
```php
App\Services\Inventory\ReceptionService         // Recepciones (principal)
App\Services\Inventory\TransferService          // ⚠️ Transferencias (incompleto)
App\Services\Inventory\ProductionService        // Producción backend
App\Services\Inventory\InventoryCountService    // Conteos físicos
```

### Costing
```php
App\Services\Costing\RecipeCostingService       // Costeo recetas
```

### Recetas
```php
App\Services\Recetas\RecalcularCostosRecetasService  // Recálculo costos
```

### Pos
```php
App\Services\Pos\PosConsumptionService          // Consumo automático POS
```

### Purchasing
```php
App\Services\Purchasing\ReceivingService        // ⚠️ Recepciones (duplicado)
App\Services\Purchasing\PurchasingService       // Lógica compras
```

### Cash
```php
App\Services\Cash\*                             // Servicios caja chica (varios)
```

### Audit
```php
App\Services\Audit\AuditLogService              // Auditoría
```

---

## PARTE 6: MODELOS ELOQUENT

### Inventory
```php
App\Models\Inv\Item
App\Models\Inv\InventoryBatch
App\Models\InventoryCount
App\Models\InventoryCountLine
App\Models\InventoryWaste
App\Models\ItemCategory
```

### Recipes
```php
App\Models\Rec\Receta
App\Models\Rec\RecetaVersion
App\Models\Rec\RecetaDetalle
App\Models\Rec\RecetaShadow
```

### Purchasing
```php
App\Models\Purchasing\PurchaseOrder
App\Models\Purchasing\PurchaseRequest
```

### Cash
```php
App\Models\CashFund
App\Models\CashFundMovement
App\Models\CashFundArqueo
```

### POS
```php
App\Models\PosMap
```

### Production
```php
App\Models\ProductionOrder
```

### Auth & Permisos
```php
App\Models\User
App\Models\Permission    // Spatie
App\Models\Role          // Spatie
```

---

## PARTE 7: DOCUMENTACIÓN V4.0 ESTADO

### Publicados y Completos
```
✅ docs/V4.0/README.md
✅ docs/V4.0/Arquitectura/README.md
✅ docs/V4.0/Frontend/Layout.md
✅ docs/V4.0/Frontend/Componentes.md
✅ docs/V4.0/Guia/Stack.md
✅ docs/V4.0/Inventario/Items.md
✅ docs/V4.0/Inventario/Recepciones.md
✅ docs/V4.0/Inventario/Disponibilidad.md
✅ docs/V4.0/Inventario/Transferencias.md
✅ docs/V4.0/Inventario/Conteos.md
✅ docs/V4.0/Inventario/Mermas.md
✅ docs/V4.0/Recetas/README.md
✅ docs/V4.0/Produccion/README.md
✅ docs/V4.0/POS/README.md
✅ docs/V4.0/Finanzas/README.md
✅ docs/V4.0/Purchasing/README.md
✅ docs/V4.0/Reports/README.md
✅ docs/V4.0/Caja/HistoricoCortes.md
```

### Históricos (no modificar)
```
docs/00.history/           ← TODO lo legacy
docs/V2/                   ← Mover a 00.history
docs/V3/                   ← Mover a 00.history
docs/_archive/             ← Respaldos empaquetados
```

---

## PARTE 8: GAPS CONSOLIDADOS

### 🔴 CRÍTICO (Bloqueantes)
1. **Motor Replenishment** - 0% implementado
   - BD: inv_stock_policy vacía
   - Código: NO existe ReplenishmentService
   - UI: Dashboard vacío
   - Algoritmos: Min-Max, SMA, POS Consumption NO implementados

2. **Consolidar servicios recepciones**
   - ReceptionService (app/Services/Inventory/)
   - ReceivingService (app/Services/Purchasing/)
   - Funcionalidad duplicada, necesita unificación

### 🟠 ALTO (Operación diaria)
3. **Versionado recetas funcional**
   - BD: receta_version existe (0 registros)
   - Código: RecipeEditor solo version=1
   - UI: NO existe comparador ni activación

4. **Flujos validación recepciones**
   - Diseño: BORRADOR→VALIDADA→POSTEADA
   - Código: ReceptionService solo marca RECIBIDO
   - Falta: Sistema tolerancias, evidencias

5. **Estados completos transferencias**
   - Diseño: BORRADOR→SOLICITADA→APROBADA→DESPACHADA→RECIBIDA
   - Código: TransferService implementación parcial (2 de 5)

6. **UI operativa producción**
   - Código: ProductionService existe
   - UI: NO existe panel operativo
   - Falta: CRUD órdenes, KPIs, registro mermas

### 🟡 MEDIO (Mejoras)
7. **API POS sin exponer**
   - RecipeCostController implementado
   - NO en routes/api.php

8. **UI ajustes rápidos mermas**
   - Wireflows documentados
   - NO implementada

9. **GUI completa permisos**
   - Backend Spatie OK
   - UI limitada (UsersIndex básico)

10. **Recetas shadow sin UI**
    - Tabla receta_shadow existe
    - Función inferir_recetas_de_ventas() existe
    - UI validación NO existe

---

## PARTE 9: PERMISOS DEFINIDOS (44 permisos)

### Formato
```
{module}.{entity}.{action}
```

### Inventario (15 permisos)
```
inventory.items.view
inventory.items.create
inventory.items.edit
inventory.items.delete
inventory.receptions.view
inventory.receptions.create
inventory.receptions.validate
inventory.receptions.post
inventory.transfers.view
inventory.transfers.create
inventory.transfers.approve
inventory.transfers.dispatch
inventory.transfers.receive
inventory.counts.view
inventory.counts.create
inventory.counts.close
inventory.wastes.view
inventory.wastes.create
```

### Recetas (6 permisos)
```
recipes.view
recipes.create
recipes.edit
recipes.delete
recipes.versions.view
recipes.versions.activate
```

### Producción (4 permisos)
```
production.orders.view
production.orders.create
production.orders.complete
production.wastes.register
```

### Compras (8 permisos)
```
purchasing.requests.view
purchasing.requests.create
purchasing.requests.approve
purchasing.orders.view
purchasing.orders.create
purchasing.orders.approve
purchasing.replenishment.view
purchasing.replenishment.edit
```

### Caja (5 permisos)
```
cashfund.view
cashfund.open
cashfund.movements.create
cashfund.arqueo.create
cashfund.approve
```

### Reportes (3 permisos)
```
reports.view
reports.export
reports.admin
```

### Administración (3 permisos)
```
admin.users.manage
admin.permissions.manage
admin.catalogs.manage
```

---

## PARTE 10: COMANDOS ARTISAN DISPONIBLES

### Recetas
```bash
php artisan recipes:sync-pos          # Sincronizar recetas con POS
php artisan recetas:recalcular-costos # Recalcular costos masivo
```

### POS
```bash
php artisan pos:reprocess             # Reprocesar tickets
```

### Sistema
```bash
php artisan queue:work                # Procesar colas
php artisan schedule:run              # Ejecutar tareas programadas
```

---

## PARTE 11: JOBS & QUEUES

### Jobs Identificados
```php
// Recetas
RecalcularCostosRecetasJob            // Recálculo costos background

// Auditoría
AuditLogJob                           // Log auditoría async

// Sistema
job_recalc_queue                      // Cola recálculos (tabla)
```

### Configuración Colas
```env
QUEUE_CONNECTION=redis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
```

---

## PARTE 12: TESTS EXISTENTES

### Estructura
```
tests/
├── Feature/                          // Tests integración
└── Unit/                             // Tests unitarios
```

### Estado
⚠️ Cobertura tests NO confirmada en auditoría  
✅ PHPUnit configurado (phpunit.xml)

---

## PARTE 13: FRONTEND - COMPONENTES REUTILIZABLES

### UI Components Blade
```blade
<x-ui.card>                           // Card contenedor
<x-ui.input>                          // Input text
<x-ui.select>                         // Select dropdown
<x-ui.button>                         // Botón
<x-ui.modal>                          // Modal
<x-ui.badge>                          // Badge
<x-ui.toast>                          // Toast notification
```

### Inventory Components
```blade
<x-inventory.item-card>               // Card ítem
<x-transfer.transfer-form>            // Formulario transferencia
```

### Layouts
```blade
layouts.terrena                       // Layout principal
layouts.app                           // Layout app
layouts.guest                         // Layout guest
```

---

## PARTE 14: ASSETS & BUILD

### Vite Config
```javascript
vite.config.js                        // Configuración Vite
```

### CSS
```css
resources/css/app.css                 // Tailwind CSS principal
```

### JS
```javascript
resources/js/app.js                   // Alpine.js + componentes
```

### Build Commands
```bash
npm run dev                           // Desarrollo
npm run build                         // Producción
```

---

## PARTE 15: ENTORNO & CONFIGURACIÓN

### .env Variables Clave
```env
# App
APP_NAME=TerrenaUI
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost/TerrenaLaravel
APP_TIMEZONE=America/Mexico_City
APP_LOCALE=es

# Database
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5433
DB_DATABASE=pos
DB_USERNAME=postgres
DB_PASSWORD="T3rr3n4#p0s"
DB_SCHEMA=selemti,public

# Cache & Queue
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

# Session
SESSION_DRIVER=database
SESSION_LIFETIME=120
```

---

## PARTE 16: PRÓXIMOS PASOS INMEDIATOS

### Semana 1 (Setup)
- [ ] Seed BD con 50 ítems, 20 recetas, 5 proveedores
- [ ] Validar migraciones actualizadas
- [ ] Tests smoke baseline

### Semana 2-3 (Sprint 1 - Recepciones)
- [ ] Consolidar ReceptionService vs ReceivingService
- [ ] Implementar flujo BORRADOR→VALIDADA→POSTEADA
- [ ] Sistema de tolerancias

### Semana 4-5 (Sprint 2 - Replenishment F1)
- [ ] Implementar algoritmo Min-Max
- [ ] Dashboard sugerencias con razón
- [ ] API REST sugerencias

### Semana 6-7 (Sprint 3 - Versionado)
- [ ] Lógica versionado recetas
- [ ] UI comparación versiones
- [ ] Activar/desactivar versiones

---

**FIN COMPENDIO SUPREMO v2.0 - COPILOT**
**Total Páginas Equivalentes:** ~35 páginas  
**Basado en:** Auditoría Fase 1 (2025-11-14) + Extracción BD selemti
