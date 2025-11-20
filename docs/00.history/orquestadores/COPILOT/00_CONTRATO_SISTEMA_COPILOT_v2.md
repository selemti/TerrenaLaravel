# CONTRATO DEL SISTEMA TERRENA v2.0
## Orquestador: COPILOT
**Fecha:** 2025-11-14  
**Versión:** 2.0  
**Esquema BD:** selemti (185 tablas, 38 vistas, 37 funciones, 22 triggers)

---

## 1. ALCANCE DEL SISTEMA

### 1.1 Módulos Core Confirmados
| Módulo | Estado | Tablas BD | Código | UI | Cobertura |
|--------|--------|-----------|--------|----|-----------| 
| **Inventario - Items** | ✅ Operativo | items (6 registros) | app/Livewire/Inventory/ItemsManage.php | resources/views/livewire/inventory/ | 95% |
| **Inventario - Recepciones** | ⚠️ Parcial | recepcion_cab, recepcion_det, inventory_batch | app/Services/Inventory/ReceptionService.php | resources/views/livewire/inventory/reception* | 70% |
| **Inventario - Transferencias** | ⚠️ Parcial | transfer_cab, transfer_det | app/Services/Inventory/TransferService.php | resources/views/livewire/transfers/ | 60% |
| **Inventario - Conteos** | ✅ Operativo | inventory_counts, inventory_count_lines | app/Livewire/InventoryCount/* | resources/views/livewire/inventory-count/ | 85% |
| **Inventario - Mermas** | ⚠️ Parcial | inventory_wastes, perdida_log, merma | app/Models/InventoryWaste.php | (UI básica) | 60% |
| **Recetas - Editor** | ✅ Operativo | receta_cab, receta_det, receta_version | app/Livewire/Recipes/RecipeEditor.php | resources/views/livewire/recipes/ | 90% |
| **Recetas - Versionado** | ❌ Pendiente | receta_version (0 registros) | RecetaVersion.php (modelo existe) | NO implementada | 40% |
| **Recetas - Costeo** | ✅ Operativo | historial_costos_receta, cost_layer | app/Services/Costing/RecipeCostingService.php | (integrado en editor) | 85% |
| **Recetas - UOM** | ✅ Operativo | cat_unidades, conversiones_unidad, cat_uom_conversion | app/Livewire/Catalogs/UnidadesIndex.php | resources/views/livewire/catalogs/ | 90% |
| **Producción** | ❌ Backend only | production_orders (0), op_produccion_cab (0) | app/Services/Inventory/ProductionService.php | NO existe UI | 40% |
| **Compras - Solicitudes/POs** | ✅ Operativo | purchase_requests, purchase_orders | app/Livewire/Purchasing/* | resources/views/livewire/purchasing/ | 80% |
| **Compras - Replenishment** | ❌ No implementado | inv_stock_policy (0 registros) | NO existe código | NO existe UI | 20% |
| **POS - Mapeo** | ✅ Operativo | pos_map (0 registros) | app/Livewire/Pos/PosMap.php | resources/views/livewire/pos/ | 90% |
| **POS - Consumos** | ⚠️ Parcial | inv_consumo_pos, inv_consumo_pos_det | app/Services/Pos/PosConsumptionService.php | (UI parcial) | 70% |
| **Caja Chica** | ✅ Operativo | cash_funds (1), cash_fund_movements (0) | app/Livewire/CashFund/* | resources/views/livewire/cash-fund/ | 90% |
| **Cortes - Precorte/Postcorte** | ✅ Operativo | precorte (33), postcorte (27), sesion_cajon (132) | app/Http/Controllers/Api/Caja/* | resources/views/caja/ | 85% |
| **Reportes & KPIs** | ✅ Operativo | 38 vistas (vw_dashboard_*, vw_sesion_*) | app/Http/Controllers/Reports/* | resources/views/reports/ | 80% |
| **Seguridad & Permisos** | ⚠️ Parcial | permissions, roles, model_has_* | Spatie Permissions | (GUI limitada) | 75% |
| **Catálogos** | ✅ Operativo | cat_almacenes, cat_proveedores, cat_sucursales | app/Livewire/Catalogs/* | resources/views/livewire/catalogs/ | 85% |

### 1.2 Arquitectura Confirmada
- **Backend:** Laravel 10 + PostgreSQL 14+
- **Frontend:** Livewire 3 + Alpine.js + Tailwind CSS
- **BD:** selemti (185 tablas, 134 FKs, 22 triggers activos)
- **Servidor:** Apache 2.4 + PHP 8.3
- **Permisos:** Spatie Laravel Permission
- **Colas:** Redis
- **Rutas:** routes/web.php (Livewire) + routes/api.php (REST)

---

## 2. FUNCIONALIDADES CONFIRMADAS

### 2.1 Inventario
✅ Alta de ítems (ItemsManage.php, InsumoCreate.php)  
✅ Recepciones (ReceptionService.php, recepcion_cab/det)  
⚠️ Transferencias (TransferService.php incompleto)  
✅ Conteos físicos (InventoryCountService.php)  
⚠️ Mermas (inventory_wastes, UI limitada)  
✅ Kardex (vw_kardex, mov_inv)

### 2.2 Recetas
✅ Editor de recetas (RecipeEditor.php)  
❌ Versionado real (tabla existe, UI no)  
✅ Costeo automático (RecipeCostingService.php)  
✅ UOM y conversiones (cat_unidades)  
⚠️ Recetas shadow (tabla existe, sin UI)

### 2.3 Producción
⚠️ Servicio backend (ProductionService.php)  
❌ UI operativa (no implementada)  
❌ KPIs rendimiento (no implementados)

### 2.4 Compras
✅ Solicitudes y POs (PurchaseRequest, PurchaseOrder)  
❌ Motor Replenishment (inv_stock_policy vacía)  
⚠️ Recepciones (ReceivingService duplicado)

### 2.5 POS
✅ Mapeo POS-Recetas (pos_map, PosMap.php)  
⚠️ Consumos (PosConsumptionService.php)  
⚠️ Reproceso tickets (pos_reprocess_log)

### 2.6 Caja & Finanzas
✅ Fondos de caja (CashFund, cash_funds)  
✅ Movimientos (cash_fund_movements)  
✅ Arqueos (cash_fund_arqueos)  
✅ Precorte/Postcorte (precorte, postcorte)  
✅ Conciliación (vistas vw_conciliacion_*)

### 2.7 Reportes
✅ Dashboards (vw_dashboard_*, ReportsController)  
✅ Ventas (SalesDetailController)  
✅ KPIs (38 vistas materializadas)  
⚠️ Exportaciones (limitadas)

### 2.8 Seguridad
✅ Roles y permisos (Spatie)  
✅ Auditoría (audit_log)  
⚠️ GUI permisos (limitada)

---

## 3. GAPS CRÍTICOS

### 🔴 CRÍTICO - Motor de Replenishment
- BD: inv_stock_policy vacía
- Código: NO existe
- UI: NO existe
- Impacto: Funcionalidad core ausente

### 🟠 ALTO - Versionado de Recetas
- BD: receta_version existe (0 registros)
- Código: Editor solo version=1
- UI: NO existe
- Impacto: Sin trazabilidad histórica

### 🟠 ALTO - Flujos validación Recepciones
- Diseño: BORRADOR→VALIDADA→POSTEADA
- Código: Solo marca RECIBIDO
- Impacto: Sin control calidad

### 🟡 MEDIO - UI Producción
- Código: ProductionService existe
- UI: NO existe panel operativo
- Impacto: Limitación cocina

### 🟡 MEDIO - Servicios duplicados
- ReceptionService vs ReceivingService
- Impacto: Confusión, mantenimiento

### 🟡 MEDIO - Estados Transferencias
- Diseño: 5 estados
- Código: Implementación parcial
- Impacto: Flujo incompleto

### 🟡 MEDIO - API POS sin exponer
- RecipeCostController no en routes
- Impacto: Funcionalidad no disponible

---

## 4. BASE DE DATOS

### 4.1 Estadísticas
- **Tablas BASE:** 147
- **Vistas:** 38
- **Funciones:** 37
- **Triggers:** 22
- **Foreign Keys:** 134

### 4.2 Tablas con datos
| Tabla | Registros |
|-------|-----------|
| items | 6 |
| postcorte | 27 |
| precorte | 33 |
| sesion_cajon | 132 |
| cash_funds | 1 |

### 4.3 Tablas vacías (BD nueva)
receta_cab, receta_det, inventory_batch, mov_inv, purchase_orders, transfer_cab, pos_map, production_orders, inv_stock_policy

### 4.4 Vistas clave
- vw_dashboard_* (13 vistas KPIs)
- vw_sesion_* (4 vistas cortes)
- vw_conciliacion_* (3 vistas finanzas)
- vw_kardex (movimientos)
- vw_replenishment_dashboard (sin datos)

### 4.5 Funciones críticas
- fn_generar_postcorte()
- fn_recipe_cost_at()
- fn_confirmar_consumo_ticket()
- recalcular_costos_periodo()
- inferir_recetas_de_ventas()

### 4.6 Triggers activos
- trg_items_assign_code
- trg_postcorte_after_insert
- trg_precorte_after_insert
- trg_ivp_after_insert

---

## 5. PRIORIDADES

### P0 - CRÍTICO
1. Motor Replenishment
2. Versionado recetas
3. Consolidar servicios recepciones

### P1 - ALTO
4. Validación recepciones
5. Estados transferencias
6. UI producción

### P2 - MEDIO
7. API POS en routes
8. UI ajustes mermas
9. GUI permisos

### P3 - BAJO
10. UI recetas shadow
11. Exportaciones avanzadas
12. Cleanup legacy

---

## 6. DEFINICIONES

**¿Qué es Terrena?**
ERP/POS para restaurantes: inventario completo, recetario con costeo, integración POS, compras, caja chica, cierre diario, reportería tiempo real.

**Usuarios:**
Almacenista, Comprador, Chef, Cajero, Gerente, Controller, Administrador

**No es:**
POS propio, contabilidad completa, RRHH, CRM, e-commerce

---

**FIN DEL CONTRATO v2.0 - COPILOT**
