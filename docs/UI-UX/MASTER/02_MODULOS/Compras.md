# MÓDULO: COMPRAS

**Última actualización**: 31 de octubre de 2025  
**Responsable**: Equipo TerrenaLaravel  
**Prioridad**: 🔴 CRÍTICO

---

## 1. RESUMEN EJECUTIVO

### 1.1 Propósito del Módulo
El módulo de Compras gestiona todo el proceso de adquisición de bienes y servicios, desde la generación automática de sugerencias de reposición hasta la recepción y costeo de productos. Incluye funcionalidades para gestión de órdenes de compra, solicitudes, cotizaciones de proveedores, políticas de stock y un **motor inteligente de sugerencias de pedidos** basado en múltiples metodologías (Min-Max, SMA, Consumo POS). El sistema implementa flujos completos de aprobación, recepción en 5 pasos y conciliación con devoluciones.

### 1.2 Estado Actual
| Aspecto | Completitud | Estado |
|---------|-------------|--------|
| **Backend** | 60% | ⚠️ Core funcional, falta refinamiento |
| **Frontend** | 60% | ⚠️ Funcional, necesita UX polish |
| **API REST** | 70% | ✅ Endpoints principales OK |
| **Base de Datos** | 85% | ✅ Estructuras principales completas |
| **Motor de Reposición** | 40% | 🔴 Implementación parcial |
| **Testing** | 25% | 🔴 Cobertura muy baja |
| **Documentación** | 80% | ✅ Completa |

**Nivel General de Completitud**: **60%** - Funcional pero necesita refinamiento crítico

### 1.3 Criticidad
- **Impacto en negocio**: CRÍTICO - Control de costos y disponibilidad de inventario
- **Dependencias**: Inventario (alta), Proveedores, Recetas, POS (consumo)
- **Usuarios afectados**: Gerentes de compras, almacenistas, administradores
- **Complejidad**: ALTA - Motor de reposición con múltiples variables

---

## 2. ESTADO ACTUAL

### 2.1 Backend

#### 2.1.1 Modelos Implementados
```php
✅ PurchaseOrder.php              // Órdenes de compra
✅ PurchaseOrderLine.php          // Líneas de órdenes (ítems)
✅ PurchaseRequest.php            // Solicitudes de compra
✅ PurchaseRequestLine.php        // Líneas de solicitudes
✅ VendorQuote.php                // Cotizaciones de proveedores
✅ VendorQuoteLine.php            // Líneas de cotizaciones
✅ ReplenishmentSuggestion.php    // Sugerencias de reposición
✅ StockPolicy.php                // Políticas de stock por ítem/sucursal
✅ PurchaseDocument.php           // Documento base (parent class)
```

**Relaciones Implementadas**:
- ✅ `PurchaseOrder` → `Vendor` (belongsTo)
- ✅ `PurchaseOrder` → `PurchaseOrderLine` (hasMany)
- ✅ `PurchaseOrderLine` → `Item` (belongsTo)
- ✅ `PurchaseOrderLine` → `Unit` (belongsTo para UOM)
- ✅ `PurchaseRequest` → `PurchaseOrder` (puede convertirse)
- ✅ `VendorQuote` → `PurchaseRequest` (belongsTo)
- ✅ `ReplenishmentSuggestion` → `Item` (belongsTo)
- ✅ `ReplenishmentSuggestion` → `Vendor` (belongsTo - proveedor preferente)
- ✅ `StockPolicy` → `Item` (belongsTo)
- ✅ `StockPolicy` → `Warehouse` (belongsTo)

**Campos Clave de PurchaseOrder**:
```sql
purchase_orders:
  - id (PK)
  - code (PO-YYYY-#####)  // Auto-generado
  - vendor_id (FK)
  - warehouse_id (FK)
  - status (draft, approved, partial, completed, cancelled)
  - order_date
  - expected_date
  - total_amount
  - notes
  - approved_by, approved_at
  - created_by, updated_by
  - timestamps
```

**Campos Clave de ReplenishmentSuggestion**:
```sql
replenishment_suggestions:
  - id (PK)
  - item_id (FK)
  - warehouse_id (FK)
  - vendor_id (FK)
  - method (min_max, sma, pos_consumption)
  - priority (urgent, high, normal, low)
  - status (pending, approved, rejected, converted)
  - current_stock
  - min_stock
  - max_stock
  - suggested_qty
  - lead_time_days
  - stockout_risk (boolean)
  - reasoning (JSON - justificación del cálculo)
  - converted_to_request_id, converted_to_order_id
  - timestamps
```

#### 2.1.2 Servicios Implementados
```php
✅ Purchasing/PurchasingService.php          // Gestión de compras (70%)
✅ Inventory/ReceivingService.php            // Recepción de mercancía (80%)
✅ Replenishment/ReplenishmentService.php    // Motor de reposición (40%)
✅ VendorQuoteService.php                    // Cotizaciones (60%)
```

**PurchasingService - Funcionalidades**:
- `createPurchaseRequest()` - Crear solicitud de compra
- `approvePurchaseRequest()` - Aprobar solicitud (cambio de estado)
- `convertRequestToOrder()` - Convertir solicitud → orden
- `createPurchaseOrder()` - Crear orden directa
- `approvePurchaseOrder()` - Aprobar orden
- `cancelPurchaseOrder()` - Cancelar orden
- `updateOrderStatus()` - Actualizar estado (partial, completed)

**ReplenishmentService - Funcionalidades** (⚠️ 40% completo):
- `generateSuggestions()` - Ejecutar motor de reposición
- `calculateMinMax()` - Método Min-Max (stock < min → sugerir max - stock)
- `calculateSMA()` - Método SMA (Simple Moving Average de consumo)
- `calculatePOSConsumption()` - Método basado en consumo POS real
- `prioritizeSuggestions()` - Calcular prioridad (URGENT si stockout_risk)
- `convertSuggestionToRequest()` - Convertir sugerencia → solicitud
- `convertSuggestionToOrder()` - Convertir sugerencia → orden (directo)
- ❌ `validatePendingOrders()` - **PENDIENTE**: Considerar órdenes en tránsito
- ❌ `calculateCoverage()` - **PENDIENTE**: Calcular días de cobertura
- ❌ `integrateLeadTime()` - **PENDIENTE**: Integrar lead time de proveedor

**ReceivingService - Funcionalidades** (documentado en Inventario):
- `createReceptionFromPO()` - Crear recepción desde orden
- `setReceptionLines()` - Configurar líneas de recepción
- `validateReception()` - Validar cantidades y calidad
- `postReception()` - Postear movimientos a inventario
- `finalizeCosting()` - Finalizar costeo (snapshot de precios)

#### 2.1.3 Funcionalidades Completadas
- ✅ **Flujo completo Solicitud → Orden**: Workflow con aprobaciones
- ✅ **Motor de reposición con 3 métodos**: Min-Max, SMA, Consumo POS
- ✅ **Conversión 1-click**: Sugerencia → Solicitud o Sugerencia → Orden
- ✅ **Recepción en 5 pasos**: Crear → Líneas → Validar → Postear → Costeo
- ✅ **Devoluciones con workflow completo**: Crear → Aprobar → Enviar → Confirmar → Nota de crédito
- ✅ **Command Artisan**: `php artisan replenishment:generate`
- ✅ **Dashboard de sugerencias**: Estadísticas y filtros básicos
- ✅ **Acciones masivas**: Aprobar/rechazar múltiples sugerencias

#### 2.1.4 Funcionalidades Pendientes
- ❌ **Validación de órdenes pendientes**: No considera órdenes en tránsito al calcular sugerencias
- ❌ **Integración con lead time de proveedor**: No calcula fecha estimada de llegada
- ⚠️ **Cálculo de cobertura (días)**: Implementación parcial, falta integrar consumo variable
- ❌ **Control de órdenes parciales**: No maneja bien recepciones parciales contra OC
- ❌ **Estacionalidad**: No considera patrones estacionales en el cálculo
- ❌ **Notificaciones automáticas**: No notifica a compradores sobre sugerencias urgentes
- ❌ **Integración con proveedores externos**: No hay API para catálogos de proveedores

---

### 2.2 Frontend

#### 2.2.1 Componentes Livewire Implementados
```
✅ Purchasing/Requests/Index.php          // Listado de solicitudes con filtros
✅ Purchasing/Requests/Create.php         // Creación de solicitud
✅ Purchasing/Requests/Detail.php         // Detalle y tracking de solicitud
✅ Purchasing/Orders/Index.php            // Listado de órdenes de compra
✅ Purchasing/Orders/Detail.php           // Detalle de orden con seguimiento
✅ Replenishment/Dashboard.php            // Dashboard principal de reposición
✅ VendorQuote/Index.php                  // Listado de cotizaciones
✅ VendorQuote/Create.php                 // Crear cotización desde solicitud
```

#### 2.2.2 Vistas Blade Implementadas
```
✅ resources/views/compras.blade.php                          // Vista principal
✅ resources/views/livewire/purchasing/requests/index.blade.php
✅ resources/views/livewire/purchasing/requests/create.blade.php
✅ resources/views/livewire/purchasing/requests/detail.blade.php
✅ resources/views/livewire/purchasing/orders/index.blade.php
✅ resources/views/livewire/purchasing/orders/detail.blade.php
✅ resources/views/livewire/replenishment/dashboard.blade.php
```

#### 2.2.3 Funcionalidades Frontend Completadas
- ✅ **Listado con filtros avanzados**: Por estado, proveedor, fecha, almacén
- ✅ **Formularios de creación/edición**: Con validación básica
- ✅ **Dashboard de sugerencias**: Estadísticas (total, por prioridad, por estado)
- ✅ **Acciones masivas**: Checkbox para aprobar múltiples sugerencias
- ✅ **Conversión 1-click**: Botones "Convertir a Solicitud" / "Convertir a Orden"
- ✅ **Indicadores de estado**: Badges con colores por estado (draft, approved, etc.)
- ✅ **Layout responsivo**: Bootstrap 5 + Tailwind CSS

#### 2.2.4 Funcionalidades Frontend Pendientes
- ⚠️ **Filtros avanzados en dashboard**: Falta filtro por categoría, riesgo de stockout
- ⚠️ **Visualización de razones del cálculo**: No muestra el "reasoning" JSON de manera amigable
- ❌ **Simulador de costo**: Preview de impacto financiero antes de ordenar
- ❌ **Recepción parcial contra OC**: UI para marcar líneas como parcialmente recibidas
- ❌ **Wizard de creación de órdenes**: Paso a paso (Proveedor → Ítems → Revisión)
- ❌ **Gráficas de tendencias**: Visualización de consumo histórico vs proyectado
- ❌ **Notificaciones en tiempo real**: Alertas de sugerencias urgentes

---

### 2.3 API REST

#### 2.3.1 Endpoints Implementados

**Gestión de Solicitudes**:
```http
✅ GET    /api/purchasing/requests              // Listado con filtros
✅ POST   /api/purchasing/requests              // Crear solicitud
✅ GET    /api/purchasing/requests/{id}         // Detalle solicitud
✅ PUT    /api/purchasing/requests/{id}/approve // Aprobar solicitud
✅ DELETE /api/purchasing/requests/{id}         // Cancelar solicitud
```

**Gestión de Órdenes**:
```http
✅ GET    /api/purchasing/orders                 // Listado de órdenes
✅ POST   /api/purchasing/orders                 // Crear orden
✅ GET    /api/purchasing/orders/{id}            // Detalle orden
✅ PUT    /api/purchasing/orders/{id}/approve    // Aprobar orden
✅ PUT    /api/purchasing/orders/{id}/cancel     // Cancelar orden
```

**Sugerencias de Reposición**:
```http
✅ GET    /api/purchasing/suggestions                   // Listado con filtros
✅ POST   /api/purchasing/suggestions/generate          // Ejecutar motor (async)
✅ POST   /api/purchasing/suggestions/{id}/approve      // Aprobar sugerencia
✅ POST   /api/purchasing/suggestions/{id}/reject       // Rechazar sugerencia
✅ POST   /api/purchasing/suggestions/{id}/convert      // Convertir (a request o order)
✅ POST   /api/purchasing/suggestions/bulk-approve      // Aprobar múltiples
```

**Recepciones** (ver módulo Inventario para detalle completo):
```http
✅ POST   /api/purchasing/receptions/create-from-po/{po_id}  // Crear recepción desde OC
✅ POST   /api/purchasing/receptions/{id}/lines              // Configurar líneas
✅ POST   /api/purchasing/receptions/{id}/validate           // Validar recepción
✅ POST   /api/purchasing/receptions/{id}/post               // Postear a inventario
✅ POST   /api/purchasing/receptions/{id}/costing            // Finalizar costeo
```

**Devoluciones**:
```http
✅ POST   /api/purchasing/returns/create-from-po/{po_id}    // Crear devolución
✅ POST   /api/purchasing/returns/{id}/approve               // Aprobar devolución
✅ POST   /api/purchasing/returns/{id}/ship                  // Enviar devolución
✅ POST   /api/purchasing/returns/{id}/confirm               // Confirmar recepción proveedor
✅ POST   /api/purchasing/returns/{id}/post                  // Postear ajuste inventario
✅ POST   /api/purchasing/returns/{id}/credit-note           // Generar nota de crédito
```

**Cotizaciones**:
```http
✅ GET    /api/purchasing/quotes                  // Listado de cotizaciones
✅ POST   /api/purchasing/quotes                  // Crear cotización
✅ PUT    /api/purchasing/quotes/{id}/select      // Seleccionar cotización ganadora
```

#### 2.3.2 Autenticación y Permisos
Todos los endpoints requieren:
- ✅ `Authorization: Bearer {token}` (Sanctum)
- ✅ Permisos específicos por acción (ver sección 2.5)

#### 2.3.3 Contratos API (Ejemplos)

**POST /api/purchasing/suggestions/generate**:
```json
{
  "warehouse_id": 1,
  "methods": ["min_max", "sma", "pos_consumption"],
  "category_ids": [1, 2, 5],
  "vendor_ids": [10, 15],
  "lookback_days": 30
}
```

**Response**:
```json
{
  "job_id": "abc123",
  "status": "processing",
  "message": "Generando sugerencias en segundo plano. Esto puede tomar unos minutos.",
  "estimated_time_seconds": 120
}
```

**GET /api/purchasing/suggestions?priority=urgent&status=pending**:
```json
{
  "data": [
    {
      "id": 456,
      "item": {
        "id": 123,
        "code": "CAT05-SUB01-00123",
        "name": "Harina de trigo kg"
      },
      "warehouse": { "id": 1, "name": "Almacén Central" },
      "vendor": { "id": 10, "name": "Proveedor ABC" },
      "method": "min_max",
      "priority": "urgent",
      "status": "pending",
      "current_stock": 15,
      "min_stock": 50,
      "max_stock": 200,
      "suggested_qty": 185,
      "lead_time_days": 3,
      "stockout_risk": true,
      "reasoning": {
        "method": "Min-Max",
        "calculation": "max_stock - current_stock = 200 - 15 = 185",
        "risk_factors": ["Stock actual por debajo del mínimo", "Lead time 3 días"]
      },
      "created_at": "2025-10-31T10:00:00Z"
    }
  ],
  "meta": {
    "total": 45,
    "per_page": 20,
    "current_page": 1
  }
}
```

---

### 2.4 Base de Datos

#### 2.4.1 Tablas Principales
```sql
✅ purchase_orders                // Órdenes de compra (header)
✅ purchase_order_lines           // Líneas de órdenes (detail)
✅ purchase_requests              // Solicitudes de compra (header)
✅ purchase_request_lines         // Líneas de solicitudes (detail)
✅ vendor_quotes                  // Cotizaciones de proveedores (header)
✅ vendor_quote_lines             // Líneas de cotizaciones (detail)
✅ replenishment_suggestions      // Sugerencias de reposición
✅ replenishment_runs             // Corridas del motor (histórico)
✅ stock_policies                 // Políticas de stock por ítem/almacén
✅ vendor_pricelist               // Lista de precios de proveedores
✅ vendor_pricelist_snapshots     // Snapshots históricos de precios
✅ vendors                        // Catálogo de proveedores
✅ items                          // Relación con inventario
✅ warehouses                     // Almacenes/sucursales
```

#### 2.4.2 Funciones y Vistas PostgreSQL
```sql
✅ fn_calculate_replenishment(item_id, method)       // Función para calcular sugerencias
✅ vw_pending_orders_by_item                         // Vista de órdenes pendientes por ítem
✅ vw_stock_coverage_days                            // Vista de días de cobertura
✅ fn_get_lead_time(vendor_id, item_id)              // Función lead time promedio
⚠️ vw_consumption_trends (parcial)                   // Vista de tendencias de consumo
```

#### 2.4.3 Índices Optimizados
```sql
✅ replenishment_suggestions: idx_repl_status, idx_repl_priority, idx_repl_item
✅ purchase_orders: idx_po_status, idx_po_vendor, idx_po_date
✅ purchase_order_lines: idx_pol_item, idx_pol_order
✅ stock_policies: idx_stockpol_item_warehouse (unique)
```

#### 2.4.4 Triggers y Constraints
```sql
✅ trg_po_update_total                    // Actualiza total_amount al insertar/actualizar líneas
✅ trg_repl_suggestion_converted          // Marca sugerencia como convertida
✅ chk_po_status                          // Constraint: status IN (draft, approved, partial, completed, cancelled)
✅ chk_repl_priority                      // Constraint: priority IN (urgent, high, normal, low)
```

---

### 2.5 Permisos Implementados

| Permiso | Descripción | Asignado a |
|---------|-------------|------------|
| `purchasing.suggested.view` | Ver pedidos sugeridos | Compras, Gerente |
| `purchasing.suggested.approve` | Aprobar sugerencias | Gerente, Admin |
| `purchasing.orders.view` | Ver órdenes de compra | Compras, Gerente, Almacén |
| `purchasing.orders.manage` | Crear/Editar órdenes | Compras, Gerente |
| `purchasing.orders.approve` | Aprobar órdenes | Gerente, Admin |
| `purchasing.orders.cancel` | Cancelar órdenes | Gerente, Admin |
| `purchasing.requests.view` | Ver solicitudes | Todos |
| `purchasing.requests.create` | Crear solicitudes | Compras, Almacén, Producción |
| `purchasing.requests.approve` | Aprobar solicitudes | Gerente, Admin |
| `purchasing.receptions.view` | Ver recepciones | Compras, Almacén |
| `purchasing.receptions.post` | Postear recepciones | Almacén, Gerente |
| `purchasing.returns.manage` | Gestionar devoluciones | Compras, Gerente |
| `can_manage_purchasing` | Permiso general de compras | Compras, Gerente, Admin |

---

## 3. FUNCIONALIDADES IMPLEMENTADAS

### 3.1 Solicitudes y Órdenes
- ✅ Estructura completa para solicitudes y órdenes
- ✅ Workflow de aprobación (draft → approved → completed)
- ✅ Integración con proveedores (selección de proveedor preferente)
- ✅ Relación con inventario (ítems/insumos)
- ✅ Conversión 1-click: Solicitud → Orden
- ✅ Tracking de estados con timestamps (approved_at, completed_at)
- ⚠️ Simulación de costo antes de ordenar (básica, mejorar)
- ⚠️ Filtros avanzados (implementados, mejorar UX)
- ❌ Wizard de creación en pasos (pendiente)
- ❌ Historial de cambios/auditoría (pendiente)

### 3.2 Recepciones
- ✅ Recepción en 5 pasos: Crear → Líneas → Validar → Postear → Costeo
- ✅ Crear recepción desde orden de compra (API: `/create-from-po/{po_id}`)
- ✅ Validación de cantidades y calidad
- ✅ Snapshot de precios al postear (tabla `item_vendor_prices`)
- ✅ Integración con inventario (movimientos en kardex)
- ⚠️ Control de recepciones parciales (básico, mejorar)
- ❌ UI para marcar líneas como parcialmente recibidas (pendiente)
- ❌ Tolerancias automáticas de cantidad (pendiente)
- ❌ Notificaciones al proveedor de discrepancias (pendiente)

### 3.3 Motor de Reposición / Replenishment (⚠️ 40% completo)
- ✅ **Método Min-Max**: Si stock < min → sugerir (max - stock)
- ✅ **Método SMA**: Simple Moving Average de consumo histórico
- ✅ **Método Consumo POS**: Basado en ventas reales del POS
- ✅ Priorización automática: URGENT (stockout_risk), HIGH, NORMAL, LOW
- ✅ Campo `reasoning` (JSON) con justificación del cálculo
- ✅ Conversión 1-click: Sugerencia → Solicitud o Sugerencia → Orden
- ✅ Dashboard con estadísticas (total sugerencias, por prioridad, por estado)
- ✅ Acciones masivas (aprobar/rechazar múltiples)
- ✅ Command Artisan: `php artisan replenishment:generate`
- ⚠️ Filtros avanzados (implementados, falta categoría y riesgo)
- ❌ **Validación de órdenes pendientes** (CRÍTICO - no considera órdenes en tránsito)
- ❌ **Integración con lead time de proveedor** (CRÍTICO - no calcula fecha de llegada)
- ⚠️ **Cálculo de cobertura (días)** (implementación parcial)
- ❌ Estacionalidad (no implementado)
- ❌ Notificaciones automáticas (pendiente)

### 3.4 Proveedores
- ✅ Catálogo de proveedores (tabla `vendors`)
- ✅ Relación ítem-proveedor (tabla `item_vendor` con proveedor preferente)
- ✅ Histórico de precios (tabla `vendor_pricelist`, `item_vendor_prices`)
- ✅ Lead time básico (campo en `item_vendor`)
- ⚠️ Calificación y evaluación de proveedores (básica)
- ❌ Información de contacto completa (pendiente ampliar modelo)
- ❌ Condiciones comerciales (crédito, descuentos) (pendiente)
- ❌ Historial de compras detallado (pendiente vista)
- ❌ Integración con catálogos externos (pendiente)

### 3.5 Devoluciones
- ✅ Workflow completo: Crear → Aprobar → Enviar → Confirmar → Postear → Nota de crédito
- ✅ API endpoints para cada paso del workflow
- ✅ Ajuste automático de inventario al postear
- ✅ Generación de nota de crédito
- ⚠️ UI para gestión de devoluciones (básica, mejorar)
- ❌ Notificaciones automáticas al proveedor (pendiente)
- ❌ Tracking de devoluciones en tránsito (pendiente)

---

## 4. GAPS IDENTIFICADOS

### 4.1 Críticos (🔴 Bloqueantes para MVP)
1. ❌ **Validación de órdenes pendientes en motor de reposición**
   - **Impacto**: Genera sugerencias duplicadas, ordena de más
   - **Problema**: `ReplenishmentService` no consulta órdenes aprobadas pero no recibidas
   - **Esfuerzo**: M (1-2 días)
   - **Solución**: Integrar vista `vw_pending_orders_by_item` en cálculo

2. ❌ **Integración con lead time de proveedor**
   - **Impacto**: No calcula fecha estimada de llegada, no previene stockouts
   - **Problema**: Campo `lead_time_days` en `item_vendor` no se usa en cálculo
   - **Esfuerzo**: S (2-4 horas)
   - **Solución**: Usar `fn_get_lead_time()` para calcular fecha de llegada

3. ⚠️ **Cálculo de cobertura (días) incompleto**
   - **Impacto**: No muestra días de cobertura estimada, dificulta decisiones
   - **Problema**: Vista `vw_stock_coverage_days` parcial, no considera consumo variable
   - **Esfuerzo**: M (1-2 días)
   - **Solución**: Ampliar vista con consumo promedio últimos 7/15/30 días

### 4.2 Altos (🟡 Importantes para calidad)
4. ❌ **Control de recepciones parciales contra OC**
   - **Impacto**: No maneja bien órdenes recibidas en múltiples entregas
   - **Esfuerzo**: L (3-5 días)
   - **Solución**: Campo `qty_received` en `purchase_order_lines`, actualizar estado a `partial`

5. ⚠️ **Filtros avanzados en dashboard de reposición**
   - **Impacto**: Dificulta encontrar sugerencias críticas
   - **Esfuerzo**: S (2-4 horas)
   - **Solución**: Agregar filtros por categoría, proveedor, riesgo de stockout

6. ⚠️ **Visualización de razones del cálculo**
   - **Impacto**: Usuarios no entienden por qué se sugiere X cantidad
   - **Esfuerzo**: S (2-4 horas)
   - **Solución**: Parsear JSON `reasoning` y mostrar en tooltip o modal

7. ❌ **Wizard de creación de órdenes**
   - **Impacto**: UX compleja en un solo formulario
   - **Esfuerzo**: M (1-2 días)
   - **Solución**: Paso 1: Proveedor, Paso 2: Ítems, Paso 3: Revisión

### 4.3 Medios (🟢 Deseables)
8. ❌ **Simulador de costo antes de ordenar**
   - **Impacto**: Previene excesos presupuestarios
   - **Esfuerzo**: M (1-2 días)
   - **Solución**: Modal con preview de costo total, impacto en inventario

9. ❌ **Estacionalidad en motor de reposición**
   - **Impacto**: No considera patrones estacionales (ej: Navidad, verano)
   - **Esfuerzo**: L (3-5 días)
   - **Solución**: Método adicional `calculateSeasonal()` con histórico anual

10. ❌ **Notificaciones automáticas**
    - **Impacto**: Compradores no reciben alertas de sugerencias urgentes
    - **Esfuerzo**: S (2-4 horas)
    - **Solución**: Listener `ReplenishmentSuggestionCreated` → Email/Slack

### 4.4 Bajos (⚪ Nice-to-have)
11. ❌ **Integración con catálogos de proveedores externos**
    - **Impacto**: Automatiza actualización de precios y disponibilidad
    - **Esfuerzo**: XL (1-2 semanas)
    - **Solución**: API REST para recibir catálogos XML/JSON de proveedores

12. ❌ **Gráficas de tendencias en dashboard**
    - **Impacto**: Visualiza consumo histórico vs proyectado
    - **Esfuerzo**: M (1-2 días)
    - **Solución**: Chart.js con datos de `vw_consumption_trends`

13. ❌ **Calificación y evaluación de proveedores**
    - **Impacto**: Mejora selección de proveedores
    - **Esfuerzo**: L (3-5 días)
    - **Solución**: Sistema de scoring (puntualidad, calidad, precio)

---

## 5. ROADMAP DEL MÓDULO

### 5.1 Fase 4: Motor de Reposición (Semanas 8-10)
**Objetivo**: Completar motor de reposición y gaps críticos

**Sprint 1 (Semana 8)**: Motor Completo
- ✅ Validación de órdenes pendientes
- ✅ Integración con lead time de proveedor
- ✅ Cálculo de cobertura (días) completo
- ✅ Testing: Unit tests para motor de reposición

**Sprint 2 (Semana 9)**: UX Refinement
- ✅ Filtros avanzados en dashboard
- ✅ Visualización de razones del cálculo
- ✅ Simulador de costo antes de ordenar
- ✅ Testing: Feature tests para workflows

**Sprint 3 (Semana 10)**: Recepciones Parciales
- ✅ Control de recepciones parciales contra OC
- ✅ UI para marcar líneas parcialmente recibidas
- ✅ Actualización automática de estado de órdenes
- ✅ Testing: E2E tests para recepciones parciales

### 5.2 Fase 5: Recetas Versionadas (Semanas 11-13)
**Integración con módulo Compras**:
- ✅ Recálculo automático de costos de recetas al cambiar precios
- ✅ Notificaciones de cambios de costo significativos
- ✅ Snapshot de costos por receta

### 5.3 Fase 6: Producción (Semanas 14-16)
**Integración con módulo Compras**:
- ✅ Solicitudes automáticas de compra al detectar falta de ingredientes
- ✅ Priorización de sugerencias para producción urgente

### 5.4 Fase 7: Quick Wins & Polish (Semanas 17-18)
**Mejoras finales**:
- ✅ Wizard de creación de órdenes
- ✅ Notificaciones automáticas
- ✅ Gráficas de tendencias
- ✅ Estacionalidad en motor (opcional)

---

## 6. SPECS TÉCNICAS

### 6.1 Arquitectura del Módulo

#### 6.1.1 Flujo de Datos: Reposición Automática
```
1. Cron job diario (o manual) → `php artisan replenishment:generate`
2. ReplenishmentService::generateSuggestions()
   - Loop por cada ítem activo
   - Consultar stock actual (vw_inventory_stock_summary)
   - Consultar política de stock (stock_policies)
   - Consultar órdenes pendientes (vw_pending_orders_by_item) [PENDIENTE]
   - Calcular según métodos: calculateMinMax() / calculateSMA() / calculatePOSConsumption()
   - Calcular prioridad: prioritizeSuggestions()
   - Guardar en replenishment_suggestions con reasoning JSON
3. Event ReplenishmentSuggestionCreated dispatched
4. Listener: SendUrgentSuggestionNotification (si priority = urgent)
5. Dashboard muestra sugerencias con filtros
6. Usuario aprueba → convierte a solicitud/orden → workflow normal
```

#### 6.1.2 Flujo de Datos: Recepción en 5 Pasos
```
1. Usuario: Crear recepción desde OC → POST /api/purchasing/receptions/create-from-po/{po_id}
   - Crea header en inventory_receptions (estado: draft)
   - Copia líneas de purchase_order_lines
   
2. Usuario: Configurar líneas → POST /api/purchasing/receptions/{id}/lines
   - Actualiza qty_received, lote, caducidad, temperatura
   
3. Usuario: Validar → POST /api/purchasing/receptions/{id}/validate
   - Valida cantidades vs esperadas (tolerancias)
   - Valida caducidad > hoy
   - Cambia estado a: validated
   
4. Usuario: Postear → POST /api/purchasing/receptions/{id}/post
   - Genera movimientos en inventory_transactions (tipo: recepcion)
   - Actualiza batches con FEFO
   - Cambia estado a: posted
   
5. Usuario: Finalizar costeo → POST /api/purchasing/receptions/{id}/costing
   - Crea snapshot en item_vendor_prices
   - Dispara evento: ReceptionPosted
   - Listener: RecalculateRecipeCosts
   - Cambia estado a: completed
```

#### 6.1.3 Diagrama de Estados: Orden de Compra
```
DRAFT (borrador)
   ↓ [approve()]
APPROVED (aprobada, esperando recepción)
   ↓ [receivePartial()]
PARTIAL (recepción parcial) ← puede repetirse
   ↓ [receiveComplete()]
COMPLETED (recepción completa)

Alternativa:
DRAFT → [cancel()] → CANCELLED
APPROVED → [cancel()] → CANCELLED
```

### 6.2 Reglas de Negocio

#### 6.2.1 Método Min-Max
```php
// Lógica: Si stock < min → sugerir (max - current_stock)
if ($currentStock < $minStock) {
    $suggestedQty = $maxStock - $currentStock;
    $priority = ($currentStock == 0) ? 'urgent' : 'high';
    $reasoning = [
        'method' => 'Min-Max',
        'calculation' => "max_stock ($maxStock) - current_stock ($currentStock) = $suggestedQty",
        'risk_factors' => ($currentStock < $minStock / 2) 
            ? ['Stock crítico', "Stock actual ($currentStock) por debajo del 50% del mínimo"]
            : ['Stock por debajo del mínimo']
    ];
}
```

#### 6.2.2 Método SMA (Simple Moving Average)
```php
// Lógica: Calcular consumo promedio últimos N días, proyectar necesidad
$lookbackDays = 30;
$avgDailyConsumption = DB::table('inventory_transactions')
    ->where('item_id', $itemId)
    ->where('type', 'consumption')
    ->where('date', '>=', now()->subDays($lookbackDays))
    ->avg('quantity');

$leadTimeDays = $leadTime ?? 3;
$safetyStockDays = 7; // Buffer de seguridad
$projectedConsumption = $avgDailyConsumption * ($leadTimeDays + $safetyStockDays);

if ($currentStock < $projectedConsumption) {
    $suggestedQty = ($maxStock - $currentStock) + $projectedConsumption;
    $reasoning = [
        'method' => 'SMA',
        'avg_daily_consumption' => round($avgDailyConsumption, 2),
        'lead_time_days' => $leadTimeDays,
        'safety_stock_days' => $safetyStockDays,
        'projected_consumption' => round($projectedConsumption, 2),
        'calculation' => "Consumo promedio diario: $avgDailyConsumption, Lead time: $leadTimeDays días"
    ];
}
```

#### 6.2.3 Método Consumo POS
```php
// Lógica: Leer ventas del POS, explotar recetas, calcular consumo de ingredientes
$sales = DB::table('pos_sales')
    ->where('sale_date', '>=', now()->subDays($lookbackDays))
    ->get();

foreach ($sales as $sale) {
    // Explotar receta (implosión) para obtener ingredientes
    $recipe = Recipe::where('item_id', $sale->item_id)->first();
    foreach ($recipe->ingredients as $ingredient) {
        $consumedQty = $ingredient->quantity * $sale->quantity;
        // Acumular consumo por ingrediente
    }
}

// Calcular sugerencia basada en consumo real
```

#### 6.2.4 Priorización de Sugerencias
```php
// Reglas de prioridad:
if ($currentStock == 0) {
    $priority = 'urgent';
    $stockoutRisk = true;
} elseif ($currentStock < $minStock * 0.5) {
    $priority = 'high';
    $stockoutRisk = true;
} elseif ($currentStock < $minStock) {
    $priority = 'normal';
    $stockoutRisk = false;
} else {
    $priority = 'low';
    $stockoutRisk = false;
}
```

### 6.3 Validaciones

#### 6.3.1 Crear Orden de Compra
```php
[
    'vendor_id' => 'required|exists:vendors,id',
    'warehouse_id' => 'required|exists:warehouses,id',
    'order_date' => 'required|date',
    'expected_date' => 'required|date|after:order_date',
    'lines' => 'required|array|min:1',
    'lines.*.item_id' => 'required|exists:items,id',
    'lines.*.quantity' => 'required|numeric|min:0.01',
    'lines.*.unit_id' => 'required|exists:units,id',
    'lines.*.unit_cost' => 'required|numeric|min:0',
]
```

#### 6.3.2 Aprobar Sugerencia de Reposición
```php
[
    'suggestion_id' => 'required|exists:replenishment_suggestions,id',
    'action' => 'required|in:approve,reject',
    'notes' => 'nullable|string|max:500'
]
```

#### 6.3.3 Recepción de Mercancía
```php
[
    'purchase_order_id' => 'required|exists:purchase_orders,id',
    'lines' => 'required|array|min:1',
    'lines.*.purchase_order_line_id' => 'required|exists:purchase_order_lines,id',
    'lines.*.qty_received' => 'required|numeric|min:0',
    'lines.*.batch_number' => 'required|string|max:50',
    'lines.*.expiry_date' => 'required|date|after:today',
    'lines.*.temperature' => 'nullable|numeric',
]
```

### 6.4 Jobs y Commands

#### 6.4.1 Artisan Commands
```bash
# Generar sugerencias de reposición (ejecutar diario)
php artisan replenishment:generate --warehouse=1 --method=all

# Generar sugerencias solo para ítems críticos
php artisan replenishment:generate --priority=urgent

# Limpiar sugerencias antiguas (>30 días)
php artisan replenishment:cleanup --days=30

# Recalcular cobertura de stock
php artisan purchasing:calculate-coverage --warehouse=1
```

#### 6.4.2 Jobs en Queue
```php
// Procesamiento asíncrono de sugerencias (motor pesado)
GenerateReplenishmentSuggestionsJob::dispatch($warehouseId, $methods);

// Notificación de sugerencias urgentes
SendUrgentSuggestionsEmailJob::dispatch($suggestions);

// Recálculo de costos de recetas tras cambio de precio
RecalculateRecipeCostsJob::dispatch($itemId);

// Actualización de estado de órdenes (partial → completed)
UpdatePurchaseOrderStatusJob::dispatch($purchaseOrderId);
```

### 6.5 Eventos y Listeners

#### 6.5.1 Eventos
```php
ReplenishmentSuggestionCreated        // Disparado al crear sugerencia
ReplenishmentSuggestionApproved       // Disparado al aprobar sugerencia
PurchaseOrderCreated                  // Disparado al crear orden
PurchaseOrderApproved                 // Disparado al aprobar orden
ReceptionPosted                       // Disparado al postear recepción (ver Inventario)
ItemPriceChanged                      // Disparado al cambiar precio de ítem
```

#### 6.5.2 Listeners
```php
SendUrgentSuggestionNotification      // Email a comprador si priority = urgent
UpdateItemLeadTime                    // Actualizar lead time promedio por proveedor
RecalculateRecipeCosts                // Recalcular costos de recetas afectadas
LogPurchaseAudit                      // Registro en audit_log
```

---

## 7. TESTING

### 7.1 Coverage Actual
- **Unit Tests**: 20% (servicios principales)
- **Feature Tests**: 25% (workflows básicos)
- **Integration Tests**: 15% (API endpoints)
- **E2E Tests**: 5% (flujos completos)

**Total Coverage**: ~25% 🔴 (Muy bajo)

### 7.2 Tests Implementados

#### 7.2.1 Unit Tests
```php
✅ PurchasingServiceTest::test_can_create_purchase_order()
✅ ReplenishmentServiceTest::test_calculates_min_max()
✅ ReplenishmentServiceTest::test_calculates_sma()
⚠️ ReplenishmentServiceTest::test_calculates_pos_consumption (básico, ampliar)
❌ ReplenishmentServiceTest::test_validates_pending_orders (PENDIENTE)
❌ ReplenishmentServiceTest::test_integrates_lead_time (PENDIENTE)
```

#### 7.2.2 Feature Tests
```php
✅ PurchaseOrderTest::test_user_can_create_order()
✅ PurchaseOrderTest::test_user_can_approve_order()
✅ ReplenishmentTest::test_generates_suggestions()
⚠️ ReplenishmentTest::test_converts_suggestion_to_order (parcial)
❌ ReceptionWorkflowTest::test_full_5_step_workflow (PENDIENTE)
❌ PartialReceptionTest (PENDIENTE)
```

#### 7.2.3 API Tests
```php
✅ PurchaseOrderApiTest::test_list_orders()
✅ PurchaseOrderApiTest::test_create_order()
✅ ReplenishmentApiTest::test_generate_suggestions()
⚠️ ReplenishmentApiTest::test_approve_suggestion (parcial)
❌ ReceptionApiTest::test_5_step_workflow (PENDIENTE)
```

### 7.3 Tests Faltantes (Críticos)

1. **ReplenishmentServiceTest::test_validates_pending_orders** - Validar que no sugiere ítems con órdenes pendientes
2. **ReplenishmentServiceTest::test_integrates_lead_time** - Validar cálculo de fecha de llegada
3. **ReplenishmentServiceTest::test_calculates_coverage** - Validar días de cobertura
4. **ReceptionWorkflowTest::test_full_5_step_workflow** - Flujo completo de recepción
5. **PartialReceptionTest** - Recepciones parciales y actualización de estado
6. **PermissionsTest** - Validar control de acceso por rol

### 7.4 Estrategia de Testing

#### 7.4.1 Prioridad 1 (Implementar en Fase 4)
- ✅ Unit tests para motor de reposición completo (todos los métodos)
- ✅ Feature tests para workflows críticos (aprobación, conversión)
- ✅ Validar reglas de negocio (priorización, cálculo de cobertura)

#### 7.4.2 Prioridad 2 (Implementar en Fase 7)
- ✅ E2E tests con Laravel Dusk para flujos completos
- ✅ Performance tests para motor de reposición (1000+ ítems)
- ✅ Integration tests para eventos y listeners

#### 7.4.3 Cobertura Meta
- **Unit Tests**: 80%
- **Feature Tests**: 70%
- **Integration Tests**: 60%
- **E2E Tests**: 50%

**Target Total**: ~70% para producción

---

## 8. INTEGRACIONES

### 8.1 Módulo de Inventario
**Dependencias**:
- Stock disponible para calcular sugerencias
- Recepciones vinculadas a órdenes de compra
- Movimientos en kardex al postear recepciones
- Precios históricos para cálculo de costos

**Endpoints compartidos**:
- `POST /api/purchasing/receptions/create-from-po/{po_id}`
- `GET /api/inventory/stock/list` (usado por motor de reposición)
- `POST /api/inventory/prices` (snapshot de precios)

**Eventos compartidos**:
- `ReceptionPosted` → dispara `UpdateRecipeCosts`
- `ItemPriceChanged` → dispara `RecalculateRecipeCosts`

### 8.2 Módulo de Recetas
**Dependencias**:
- Costos de ingredientes afectan costo de recetas
- Implosión de recetas para calcular consumo POS
- Versionado automático al cambiar precios

**Eventos compartidos**:
- `ItemPriceChanged` → recalcula recetas afectadas
- `RecipeCostChanged` → notifica a gerente

### 8.3 Módulo POS (FloreantPOS)
**Dependencias**:
- Consumo POS para método de reposición `pos_consumption`
- Lectura de ventas para calcular consumo real
- Implosión de recetas para obtener ingredientes

**Integración**:
- **Vista**: `vw_pos_sales_with_recipes` (ventas con recetas explotadas)
- **Función**: `fn_calculate_consumption_from_pos(item_id, days)`

### 8.4 Módulo de Producción
**Dependencias**:
- Solicitudes automáticas al detectar falta de ingredientes
- Priorización de sugerencias para producción urgente

**Eventos compartidos**:
- `ProductionScheduled` → valida disponibilidad de ingredientes
- `IngredientsShort` → genera sugerencias con prioridad HIGH

### 8.5 Módulo de Reportes
**Dependencias**:
- KPIs de compras (cumplimiento, tiempo de entrega)
- Análisis de proveedores (calidad, puntualidad)
- Reportes de exactitud de sugerencias

**Endpoints compartidos**:
- `GET /api/reports/purchasing/performance`
- `GET /api/reports/purchasing/vendor-scorecard`
- `GET /api/reports/replenishment/accuracy`

---

## 9. KPIs MONITOREADOS

### 9.1 KPIs Operativos
| KPI | Fórmula | Meta | Frecuencia |
|-----|---------|------|------------|
| **Tasa de cumplimiento de pedidos** | `(Órdenes recibidas completas / Total órdenes) * 100` | > 95% | Semanal |
| **Tiempo promedio de entrega** | `AVG(fecha_recepción - fecha_orden)` | < 5 días | Semanal |
| **Nivel de servicio** | `(Demanda satisfecha / Demanda total) * 100` | > 98% | Diario |
| **Stockouts evitados** | `COUNT(sugerencias aprobadas que previnieron stockout)` | Track | Mensual |
| **Precisión de sugerencias** | `(Sugerencias aprobadas / Total sugerencias) * 100` | > 80% | Mensual |

### 9.2 KPIs Financieros
| KPI | Fórmula | Meta | Frecuencia |
|-----|---------|------|------------|
| **Costo de adquisición** | `SUM(total_amount) / Total ítems recibidos` | Track | Mensual |
| **Desviación del presupuesto** | `(Gasto real - Presupuesto) / Presupuesto * 100` | < 5% | Mensual |
| **Rotación de inventario** | `COGS / Avg Inventory Value` | > 12 veces/año | Mensual |
| **Ahorro por negociación** | `SUM(precio_anterior - precio_nuevo) * qty_ordered` | Track | Mensual |

### 9.3 KPIs de Calidad
| KPI | Fórmula | Meta | Frecuencia |
|-----|---------|------|------------|
| **Tiempo de reposición** | `AVG(fecha_recepción - fecha_sugerencia)` | < 7 días | Mensual |
| **Proveedores puntuales** | `(Entregas a tiempo / Total entregas) * 100` | > 90% | Mensual |
| **Tasa de devoluciones** | `(Devoluciones / Total recepciones) * 100` | < 2% | Mensual |
| **Exactitud de recepciones** | `(Recepciones sin discrepancias / Total) * 100` | > 95% | Semanal |

---

## 10. REFERENCIAS

### 10.1 Links a Código
- **Modelos**: `app/Models/PurchaseOrder.php`, `app/Models/ReplenishmentSuggestion.php`
- **Servicios**: `app/Services/Purchasing/PurchasingService.php`, `app/Services/Replenishment/ReplenishmentService.php`
- **Controladores**: `app/Http/Controllers/PurchasingController.php`
- **Componentes Livewire**: `app/Http/Livewire/Purchasing/*.php`, `app/Http/Livewire/Replenishment/*.php`
- **Vistas**: `resources/views/livewire/purchasing/*.blade.php`
- **Migraciones**: `database/migrations/*_create_purchase_orders_table.php`
- **Seeders**: `database/seeders/PurchaseOrderSeeder.php`
- **Commands**: `app/Console/Commands/GenerateReplenishment.php`

### 10.2 Documentación Externa
- **Laravel 11 Eloquent**: https://laravel.com/docs/11.x/eloquent
- **Livewire 3**: https://livewire.laravel.com/docs
- **PostgreSQL Functions**: https://www.postgresql.org/docs/9.5/functions.html
- **Inventory Management Best Practices**: https://www.netsuite.com/portal/resource/articles/inventory-management/replenishment.shtml

### 10.3 Documentación Interna
- **Plan Maestro**: `docs/UI-UX/MASTER/04_ROADMAP/00_PLAN_MAESTRO.md`
- **Módulo Inventario**: `docs/UI-UX/MASTER/02_MODULOS/Inventario.md`
- **Design System**: `docs/UI-UX/MASTER/03_ARQUITECTURA/02_DESIGN_SYSTEM.md`
- **Database Schema**: `docs/UI-UX/MASTER/03_ARQUITECTURA/04_DATABASE_SCHEMA.md`
- **API Contracts**: `docs/UI-UX/MASTER/03_ARQUITECTURA/03_API_CONTRACTS.md`

### 10.4 Issues Relacionados
- **GitHub Issues**: (Agregar links cuando se creen)
  - #XXX: Implementar validación de órdenes pendientes en motor
  - #XXX: Integrar lead time de proveedor en cálculo
  - #XXX: Control de recepciones parciales contra OC

---

## 11. CHANGELOG

### 2025-10-31
- ✨ Creación de documentación completa del módulo Compras
- ✨ Consolidación de `Definiciones/Compras.md` + `Status/STATUS_Compras.md`
- ✨ Análisis de gaps críticos del motor de reposición
- ✨ Specs técnicas detalladas con ejemplos de código
- ✨ Estrategia de testing y cobertura
- ✨ Roadmap específico con Fase 4 dedicada

---

## 12. PRÓXIMOS PASOS INMEDIATOS

### Esta Semana (Prioridad 🔴)
1. ✅ **Validar documentación con Tech Lead**
2. ⏳ **Crear issues en GitHub** para gaps críticos del motor
3. ⏳ **Asignar tareas** a desarrolladores/IAs
4. ⏳ **Iniciar Sprint 1 de Fase 4**: Validación órdenes pendientes + lead time

### Próximas 2 Semanas
- Completar Sprint 1 y Sprint 2 de Fase 4 (Motor de Reposición)
- Aumentar cobertura de tests a 50%
- Refinar UX de dashboard de sugerencias

---

**Mantenido por**: Equipo TerrenaLaravel  
**Próxima review**: Después de completar Fase 4  
**Feedback**: Enviar a tech-lead@terrena.com

---

**🎉 Documentación completada - Compras Module v1.0**
