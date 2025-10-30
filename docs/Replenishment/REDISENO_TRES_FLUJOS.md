# REDISEÑO OPERATIVO: SISTEMA COMPLETO DE REPOSICIÓN Y TRAZABILIDAD

**Fecha:** 2025-10-24
**Versión:** 2.1 - Aprobado con plan de fases
**Alcance:** Diseño completo desde sugerencias hasta devoluciones
**Estado:** ✅ Aprobado condicionalmente - Listo para implementación por fases

---

## 📅 PLAN DE IMPLEMENTACIÓN POR FASES

### **Estrategia de Implementación**

El sistema se implementará en **3 fases modulares** para minimizar riesgo y permitir validación operativa incremental:

```
FASE 1: COMPRAS (2-3 semanas)
  ├─ Sprint 1: Sugerencias + Requests
  ├─ Sprint 2: Orders + Recepciones
  └─ Sprint 3: Devoluciones + Testing

FASE 2: PRODUCCIÓN (2-3 semanas)
  ├─ Sprint 1: Sugerencias + Consolidación
  ├─ Sprint 2: Órdenes + QC
  └─ Sprint 3: Distribución + Devoluciones

FASE 3: TRANSFERENCIAS (1-2 semanas)
  ├─ Sprint 1: Sugerencias + Órdenes
  └─ Sprint 2: Recepciones + Devoluciones
```

### **FASE 1: COMPRAS (APROBADA PARA INICIO)**

#### **Sprint 1.1: Sugerencias de Compra**
**Duración:** 3-5 días

**Entregables:**
1. **Migrations:**
   - `create_purchase_suggestions_table.php`
   - `create_purchase_suggestion_lines_table.php`
   - `alter_purchase_requests_add_fields.php` (fecha_requerida, almacen_destino_id, urgente)

2. **Modelos:**
   - `PurchaseSuggestion.php` (con relaciones, scopes, accessors)
   - `PurchaseSuggestionLine.php`
   - Actualizar `PurchaseRequest.php` con nuevos campos

3. **Servicios:**
   - `StockCalculatorService.php` (compartido)
   - `StockPolicyService.php` (compartido)
   - `PurchaseSuggestionService.php`
     - `generateSuggestions(array $options): array`
     - `createManualSuggestion(array $data): PurchaseSuggestion`
     - `approveSuggestion(int $id, ?int $userId): bool`
     - `convertToRequest(int $id): int` (retorna purchase_request_id)

4. **API Endpoints:**
   - `GET /api/purchasing/suggestions`
   - `POST /api/purchasing/suggestions/generate`
   - `POST /api/purchasing/suggestions` (crear manual)
   - `POST /api/purchasing/suggestions/{id}/approve`
   - `POST /api/purchasing/suggestions/{id}/convert`

5. **Command:**
   - `php artisan purchasing:generate-suggestions` (para cron diario)

**Criterios de Aceptación:**
- [ ] Se generan sugerencias automáticas basadas en stock_policy
- [ ] Se pueden aprobar/rechazar sugerencias
- [ ] Se convierten a purchase_requests correctamente
- [ ] Cálculo de consumo promedio funciona
- [ ] Tests unitarios de PurchaseSuggestionService

#### **Sprint 1.2: Órdenes y Recepciones**
**Duración:** 4-6 días

**Entregables:**
1. **Migrations:**
   - `alter_purchase_orders_add_states.php` (estados ampliados)
   - `alter_recepcion_cab_add_fields.php` (diferencias, estados)
   - `alter_recepcion_det_add_qty_fields.php`

2. **Servicios:**
   - `PurchaseOrderService.php` (si no existe)
     - `createFromRequest(int $requestId): int`
     - `sendToVendor(int $orderId): bool`
     - Estados: APROBADA → ENVIADA_A_PROVEEDOR → EN_TRANSITO

   - `ReceptionService.php` (ampliar existente)
     - `createFromPurchaseOrder(int $orderId, array $lines): int`
     - `validateDifferences(int $receptionId): array`
     - `postToInventory(int $receptionId): bool` (genera mov_inv)

3. **API Endpoints:**
   - `POST /api/purchasing/orders/{id}/send`
   - `POST /api/purchasing/orders/{id}/receive` (crear recepción)
   - `POST /api/inventory/receptions/{id}/validate`
   - `POST /api/inventory/receptions/{id}/post` (postear a inventario)

**Criterios de Aceptación:**
- [ ] Purchase orders cambian estados correctamente
- [ ] Recepciones registran diferencias qty_ordenada vs qty_recibida
- [ ] Posteo a inventario genera mov_inv con ref_tipo='PURCHASE_ORDER'
- [ ] Diferencias > umbral requieren aprobación

#### **Sprint 1.3: Devoluciones a Proveedor**
**Duración:** 3-4 días

**Entregables:**
1. **Migrations:**
   - `create_purchase_returns_table.php`
   - `create_purchase_return_lines_table.php`

2. **Modelos:**
   - `PurchaseReturn.php`
   - `PurchaseReturnLine.php`

3. **Servicios:**
   - `PurchaseReturnService.php`
     - `createReturn(int $purchaseOrderId, array $lines): int`
     - `approve(int $returnId): bool`
     - `postToInventory(int $returnId): bool` (genera mov_inv negativo)

4. **API Endpoints:**
   - `POST /api/purchasing/returns`
   - `POST /api/purchasing/returns/{id}/approve`
   - `POST /api/purchasing/returns/{id}/post`

**Criterios de Aceptación:**
- [ ] Se pueden crear devoluciones desde purchase_orders
- [ ] Posteo genera mov_inv tipo DEVOLUCION_PROVEEDOR (qty negativa)
- [ ] Tracking de guía de envío y nota de crédito

---

### **FASE 2: PRODUCCIÓN** (Pendiente aprobación Fase 1)

**Sprint 2.1:** Sugerencias + Consolidación
**Sprint 2.2:** Órdenes + QC
**Sprint 2.3:** Distribución + Devoluciones

*(Detalle completo se documentará al completar Fase 1)*

---

### **FASE 3: TRANSFERENCIAS** (Pendiente aprobación Fase 2)

**Sprint 3.1:** Sugerencias + Órdenes
**Sprint 3.2:** Recepciones + Devoluciones

*(Detalle completo se documentará al completar Fase 2)*

---

## 🎯 VISIÓN OPERATIVA

Este documento describe el sistema completo de reposición para una **cadena de restaurantes con cocina central** y múltiples sucursales consumidoras. El sistema cubre:

1. **Generación de sugerencias** (basadas en políticas de stock y demanda)
2. **Solicitudes y órdenes** (compras, producción, transferencias)
3. **Recepciones** (con diferencias y validaciones)
4. **Devoluciones** (a proveedores, internas, de producción)
5. **Trazabilidad completa** (Kardex, movimientos, auditoría)

### **Roles Operativos**
- **Compras:** Proveedores, cotizaciones, órdenes de compra
- **Cocina Central:** Producción consolidada, recetas, insumos
- **Logística:** Transferencias entre almacenes/sucursales
- **Almacén:** Recepciones, validaciones, devoluciones
- **Gerencia:** Aprobaciones, análisis, control

---

## 📊 ARQUITECTURA GENERAL DEL SISTEMA

```
┌─────────────────────────────────────────────────────────────────┐
│                    POLÍTICAS DE STOCK                           │
│  (stock_policy: min, max, reorder_point, lead_time)            │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                 MOTOR DE SUGERENCIAS                            │
│  Analiza: stock_actual, consumo_promedio, demanda_proyectada   │
│  Genera: purchase_suggestions, production_suggestions,         │
│          transfer_suggestions                                   │
└──────┬──────────────┬──────────────────┬───────────────────────┘
       │              │                  │
       ▼              ▼                  ▼
┌────────────┐  ┌────────────┐    ┌─────────────┐
│ PURCHASE   │  │ PRODUCTION │    │ TRANSFER    │
│ REQUESTS   │  │ REQUESTS   │    │ REQUESTS    │
└─────┬──────┘  └─────┬──────┘    └──────┬──────┘
      │               │                   │
      ▼               ▼                   ▼
┌────────────┐  ┌────────────┐    ┌─────────────┐
│ PURCHASE   │  │ PRODUCTION │    │ TRANSFER    │
│ ORDERS     │  │ ORDERS     │    │ ORDERS      │
└─────┬──────┘  └─────┬──────┘    └──────┬──────┘
      │               │                   │
      └───────┬───────┴──────────┬────────┘
              ▼                  ▼
       ┌─────────────┐    ┌─────────────┐
       │ RECEPCIONES │    │ MOVIMIENTOS │
       │ (recepcion_ │    │ (mov_inv /  │
       │  cab/det)   │    │  kardex)    │
       └──────┬──────┘    └─────────────┘
              │
              ▼
       ┌─────────────┐
       │ DEVOLUCIONES│
       │ (purchase/  │
       │  production/│
       │  transfer   │
       │  returns)   │
       └─────────────┘
```

---

## 🔄 FLUJO 1: COMPRAS A PROVEEDORES

### **Objetivo Operativo**
Abastecer inventario mediante compras externas cuando el stock cae por debajo del mínimo.

### **Proceso Completo**

```
SUGERENCIA → SOLICITUD → COTIZACIÓN → ORDEN → RECEPCIÓN → [DEVOLUCIÓN]
```

### **1.1 Sugerencias de Compra**

**Tabla Propuesta:** `purchase_suggestions` (nueva)

```sql
CREATE TABLE selemti.purchase_suggestions (
    id BIGSERIAL PRIMARY KEY,
    folio VARCHAR(20) UNIQUE NOT NULL,  -- PSC-2025-001234
    sucursal_id BIGINT REFERENCES selemti.cat_sucursales(id),
    almacen_id BIGINT REFERENCES selemti.cat_almacenes(id),
    estado VARCHAR(20) DEFAULT 'PENDIENTE',  -- PENDIENTE, REVISADA, APROBADA, CONVERTIDA, RECHAZADA
    prioridad VARCHAR(20) DEFAULT 'NORMAL',  -- URGENTE, ALTA, NORMAL, BAJA
    origen VARCHAR(20) DEFAULT 'AUTO',  -- AUTO, MANUAL, EVENTO_ESPECIAL

    -- Cálculos
    total_items INT DEFAULT 0,
    total_estimado NUMERIC(18,2) DEFAULT 0,

    -- Auditoría
    sugerido_en TIMESTAMP DEFAULT NOW(),
    sugerido_por_user_id BIGINT REFERENCES users(id),
    revisado_por_user_id BIGINT REFERENCES users(id),
    revisado_en TIMESTAMP,
    convertido_a_request_id BIGINT REFERENCES selemti.purchase_requests(id),
    convertido_en TIMESTAMP,

    -- Metadatos
    dias_analisis INT DEFAULT 7,
    consumo_promedio_calculado BOOLEAN DEFAULT TRUE,
    notas TEXT,
    meta JSONB,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE selemti.purchase_suggestion_lines (
    id BIGSERIAL PRIMARY KEY,
    suggestion_id BIGINT NOT NULL REFERENCES selemti.purchase_suggestions(id) ON DELETE CASCADE,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),

    -- Stock y políticas
    stock_actual NUMERIC(18,6) DEFAULT 0,
    stock_min NUMERIC(18,6) NOT NULL,
    stock_max NUMERIC(18,6) NOT NULL,
    reorder_point NUMERIC(18,6),

    -- Consumo y demanda
    consumo_promedio_diario NUMERIC(18,6) DEFAULT 0,
    dias_cobertura_actual INT DEFAULT 0,
    demanda_proyectada NUMERIC(18,6) DEFAULT 0,

    -- Cantidades
    qty_sugerida NUMERIC(18,6) NOT NULL,
    qty_ajustada NUMERIC(18,6),  -- Si el usuario modifica
    uom VARCHAR(10) NOT NULL,

    -- Costos
    costo_unitario_estimado NUMERIC(18,6),
    costo_total_linea NUMERIC(18,2),

    -- Proveedor recomendado
    proveedor_sugerido_id BIGINT REFERENCES selemti.cat_proveedores(id),
    ultimo_precio_compra NUMERIC(18,6),
    fecha_ultima_compra DATE,

    notas TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

**Cálculo de Sugerencias:**
```php
// Pseudo-código
foreach ($items_con_politica as $item) {
    $stockActual = StockCalculator::getCurrentStock($item->id, $almacen_id);
    $stockPolicy = StockPolicy::getPolicyFor($item->id, $sucursal_id);

    if ($stockActual < $stockPolicy->min_qty) {
        $consumoPromedio = StockCalculator::getAverageDailyConsumption(
            $item->id,
            $almacen_id,
            $dias = 7
        );

        $diasCobertura = $consumoPromedio > 0
            ? floor($stockActual / $consumoPromedio)
            : 999;

        $qtySugerida = $stockPolicy->reorder_qty ?? ($stockPolicy->max_qty - $stockActual);

        // Ajustar a presentación del proveedor
        $proveedor = $item->proveedorHabitual;
        if ($proveedor && $proveedor->presentacion_minima) {
            $qtySugerida = ceil($qtySugerida / $proveedor->presentacion_minima)
                * $proveedor->presentacion_minima;
        }

        PurchaseSuggestionLine::create([...]);
    }
}
```

### **1.2 Solicitudes de Compra**

**Tabla Existente:** `selemti.purchase_requests` ✅
**Tabla Existente:** `selemti.purchase_request_lines` ✅

**Estados Actuales:**
```
BORRADOR → COTIZADA → APROBADA → ORDENADA → CANCELADA
```

**Estados Propuestos (ampliados):**

**CORE (Versión 1.0 - Mínimo Funcional):**
```
BORRADOR → APROBADA → ORDENADA → CERRADA
```

**EXTENDIDOS (Versiones Futuras):**
```
BORRADOR
  ↓
[ENVIADA_A_COTIZAR]  (mejora futura: cotizaciones a proveedores)
  ↓
[COTIZADA]  (mejora futura: al menos 1 cotización recibida)
  ↓
APROBADA  (gerencia aprueba)
  ↓
ORDENADA  (se generó purchase_order)
  ↓
[RECIBIDA_PARCIAL]  (mejora futura: recepciones parciales)
  ↓
[RECIBIDA_TOTAL]  (mejora futura: tracking de recepción completa)
  ↓
CERRADA
```

**Nota:** Los estados entre `[]` son EXTENDIDOS. La implementación Fase 1 usará solo estados CORE.

**Campos Adicionales Necesarios:**
- `fecha_requerida` (DATE) - Cuándo se necesita el material
- `almacen_destino_id` (BIGINT) - Dónde se recibirá
- `justificacion` (TEXT) - Por qué se solicita
- `urgente` (BOOLEAN) - Marca de urgencia

### **1.3 Órdenes de Compra**

**Tabla Existente:** `selemti.purchase_orders` ✅
**Tabla Existente:** `selemti.purchase_order_lines` ✅

**Estados Actuales:** Revisar modelo existente

**Estados Propuestos:**

**CORE (Versión 1.0):**
```
BORRADOR → APROBADA → EN_TRANSITO → CERRADA
```

**EXTENDIDOS (Versiones Futuras):**
```
BORRADOR
  ↓
APROBADA  (lista para enviar)
  ↓
[ENVIADA_A_PROVEEDOR]  (mejora: tracking de envío de PDF/email)
  ↓
[CONFIRMADA_POR_PROVEEDOR]  (mejora: confirmación del proveedor)
  ↓
EN_TRANSITO  (material en camino)
  ↓
[RECIBIDA_PARCIAL]  (mejora: recepciones parciales)
  ↓
[RECIBIDA_TOTAL]  (mejora: tracking completo)
  ↓
CERRADA
```

### **1.4 Recepciones de Compra**

**Tabla Existente:** `selemti.recepcion_cab` ✅
**Tabla Existente:** `selemti.recepcion_det` ✅

**Campos Críticos a Validar:**
- `ref_tipo` - Debe incluir 'PURCHASE_ORDER'
- `ref_id` - FK a purchase_orders(id)
- `estado` - Debe soportar estados parciales

**Estados Propuestos:**

**CORE (Versión 1.0):**
```
EN_PROCESO → VALIDADA → POSTEADA_A_INVENTARIO → CERRADA
```

**EXTENDIDOS (Versiones Futuras):**
```
EN_PROCESO  (capturando cantidades)
  ↓
VALIDADA  (cantidades confirmadas)
  ↓
[CON_DIFERENCIAS]  (mejora: flag especial si qty_recibida ≠ qty_ordenada)
  ↓
[APROBADA]  (mejora: gerente aprueba diferencias antes de postear)
  ↓
POSTEADA_A_INVENTARIO  ⚠️ CRÍTICO: genera movimientos DEFINITIVOS en kardex
  ↓
CERRADA
```

### ⚠️ **REGLA CRÍTICA: POSTEADA_A_INVENTARIO**

Cuando un documento (recepción, producción, transferencia, devolución) pasa al estado `POSTEADA_A_INVENTARIO`:

1. **Se generan renglones DEFINITIVOS en `selemti.mov_inv` (Kardex)**
2. **Estos renglones NO se editan ni se borran jamás**
3. **Son la fuente de verdad para valuación de inventario y auditoría**
4. **Si hay errores posteriores:**
   - NO se modifica el mov_inv original
   - Se crea un **movimiento compensatorio** (ajuste, devolución, etc.)
   - Ejemplo: Si se recibieron 100 y debieron ser 95:
     ```sql
     -- Movimiento original (INMUTABLE):
     INSERT INTO mov_inv (tipo, qty, ...) VALUES ('COMPRA', 100, ...);

     -- Corrección (NUEVO movimiento):
     INSERT INTO mov_inv (tipo, qty, ...) VALUES ('AJUSTE_INVENTARIO', -5, ...);
     ```

5. **Campos obligatorios en cada mov_inv:**
   - `tipo` (ej: COMPRA, PRODUCCION_ENTRADA, TRANSFERENCIA_SALIDA)
   - `ref_tipo` (ej: PURCHASE_ORDER, PRODUCTION_ORDER, TRANSFER)
   - `ref_id` (FK al documento origen)
   - `item_id`, `almacen_id`, `qty`, `uom`, `costo_unitario`, `user_id`, `ts`

**Implicación Operativa:**
- Una vez posteado, el documento es **inmutable financieramente**
- Los reportes de valuación de inventario dependen de la integridad de `mov_inv`
- Cualquier ajuste requiere crear un nuevo documento de ajuste

---

## 🔧 CONFIGURACIÓN PARAMETRIZABLE

**IMPORTANTE:** Todos los umbrales y valores de negocio deben ser configurables, **NO hardcodeados** en el código.

### **Umbrales de Aprobación Automática**

```php
// ❌ MAL - Hardcodeado
if ($diferencia_pct < 5) {
    $this->aprobarAutomaticamente();
}

// ✅ BIEN - Parametrizable
if ($diferencia_pct < config('inventory.reception_tolerance_pct', 5)) {
    $this->aprobarAutomaticamente();
}
```

### **Parámetros Requeridos en `config/inventory.php`:**

```php
return [
    // Tolerancias de diferencias
    'reception_tolerance_pct' => env('INVENTORY_RECEPTION_TOLERANCE_PCT', 5), // 5%
    'transfer_tolerance_pct' => env('INVENTORY_TRANSFER_TOLERANCE_PCT', 3),   // 3%
    'production_yield_tolerance_pct' => env('INVENTORY_PRODUCTION_TOLERANCE_PCT', 10), // 10%

    // Cálculo de consumo
    'consumption_analysis_days' => env('INVENTORY_CONSUMPTION_DAYS', 7),  // 7 días
    'min_data_points_for_avg' => env('INVENTORY_MIN_DATA_POINTS', 3),    // Mínimo 3 ventas

    // Políticas de stock
    'safety_stock_pct' => env('INVENTORY_SAFETY_STOCK_PCT', 20),  // 20% sobre min
    'reorder_buffer_days' => env('INVENTORY_REORDER_BUFFER_DAYS', 2),  // 2 días buffer

    // Sugerencias automáticas
    'auto_generate_suggestions_enabled' => env('INVENTORY_AUTO_SUGGEST', true),
    'auto_approve_threshold_pct' => env('INVENTORY_AUTO_APPROVE_PCT', 0), // 0 = no auto-aprobar

    // Caducidad de sugerencias
    'suggestion_expiry_days' => env('INVENTORY_SUGGESTION_EXPIRY_DAYS', 7),
    'suggestion_urgent_threshold_days' => env('INVENTORY_URGENT_THRESHOLD_DAYS', 1),

    // Producción
    'min_batch_utilization_pct' => env('PRODUCTION_MIN_BATCH_PCT', 60),  // 60% del batch mínimo
    'production_lead_time_hours' => env('PRODUCTION_LEAD_TIME_HOURS', 24),

    // Transferencias
    'min_transfer_value' => env('TRANSFER_MIN_VALUE', 500),  // $500 mínimo
    'transfer_consolidation_hours' => env('TRANSFER_CONSOLIDATION_HOURS', 4),  // Agrupar en 4h
];
```

### **Uso en Servicios:**

```php
class PurchaseSuggestionService
{
    public function generateSuggestions(array $options = []): array
    {
        $diasAnalisis = $options['dias_analisis']
            ?? config('inventory.consumption_analysis_days', 7);

        $umbralUrgente = config('inventory.urgent_threshold_days', 1);

        // ...
    }
}
```

### **Tabla de Configuración en BD (Opcional - Fase Futura):**

Para configuración por sucursal o contexto específico:

```sql
CREATE TABLE selemti.config_parametros (
    id SERIAL PRIMARY KEY,
    clave VARCHAR(100) UNIQUE NOT NULL,
    valor TEXT NOT NULL,
    tipo VARCHAR(20) DEFAULT 'string',  -- string, int, float, boolean, json
    categoria VARCHAR(50),
    descripcion TEXT,
    sucursal_id BIGINT REFERENCES selemti.cat_sucursales(id),  -- NULL = global
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Ejemplo:
INSERT INTO config_parametros (clave, valor, tipo, categoria, descripcion) VALUES
('reception_tolerance_pct', '5', 'float', 'inventory', 'Tolerancia % en recepciones'),
('auto_approve_small_diffs', 'true', 'boolean', 'inventory', 'Auto-aprobar diferencias pequeñas');
```

---

## 🔌 INTEGRACIÓN POS / VENTAS

### **Asunciones para Alimentación de Consumos**

El sistema de reposición depende del cálculo de **consumo promedio diario** basado en ventas POS.

**Asunciones de Integración:**

#### **1. Origen de Datos de Consumo**

**Fuente:** Tabla `public.ticket` + `public.ticket_item` (Floreant POS - PostgreSQL)

```sql
-- Consumo diario calculado desde ventas
SELECT
    ti.item_id,
    DATE(t.create_date) AS fecha,
    SUM(ti.quantity) AS qty_vendida
FROM public.ticket t
INNER JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE t.voided = false
  AND t.refunded = false
  AND DATE(t.create_date) >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY ti.item_id, DATE(t.create_date);
```

#### **2. Explosión de Recetas (Recipe Explosion)**

**Problema:** POS vende `MenuItem` (ej: "Hamburguesa Especial"), pero inventario controla `Items` (ej: "Pan", "Carne", "Queso").

**Solución:** Explosión de recetas para calcular consumo de insumos:

```php
// Pseudo-código
$ventaHamburguesa = 10;  // Se vendieron 10 hamburguesas

$receta = Receta::where('menu_item_id', 'HAMBUR001')->first();

foreach ($receta->detalles as $ingrediente) {
    $consumoInsumo = $ventaHamburguesa * $ingrediente->qty_por_unidad;

    // Registrar consumo teórico de insumo
    StockCalculator::registerTheoreticalConsumption(
        $ingrediente->item_id,
        $consumoInsumo,
        'VENTA_POS',
        $ticket->id
    );
}
```

#### **3. Proceso de Sincronización**

**Opción A: Real-Time (Recomendado para Fase 1)**

- Hook después de cerrar ticket en POS
- Explosionar receta inmediatamente
- Registrar movimientos en `mov_inv` tipo `VENTA`

```php
// Event listener
Event::listen(TicketClosed::class, function ($event) {
    $ticket = $event->ticket;

    foreach ($ticket->items as $menuItem) {
        $receta = Receta::whereMenuItemId($menuItem->id)->first();

        if ($receta) {
            RecipeExplosionService::explodeAndRegisterConsumption(
                $receta,
                $menuItem->quantity,
                $ticket->sucursal_id,
                $ticket->id
            );
        }
    }
});
```

**Opción B: Batch Process (Mejora Futura)**

- Cron cada hora que procesa tickets no explotados
- Tabla intermedia `pos_consumption_pending`
- Permite re-procesamiento si hay errores

```bash
# Cron entry
0 * * * * php artisan pos:explode-recipes --last-hour
```

#### **4. Manejo de Modificadores**

**Problema:** Cliente pide "Hamburguesa sin cebolla, extra queso"

**Solución:**

```sql
-- ticket_item_modifier tiene los cambios
SELECT
    ti.id,
    ti.item_id,
    tim.modifier_id,
    tim.quantity_change  -- +1 para extra, -1 para sin
FROM ticket_item ti
INNER JOIN ticket_item_modifier tim ON tim.ticket_item_id = ti.id;
```

```php
// Ajustar explosión de receta
$baseRecipe = Receta::find($menuItem->recipe_id);
foreach ($menuItem->modifiers as $modifier) {
    if ($modifier->affects_inventory) {
        // Ajustar qty del ingrediente afectado
        $ingrediente = $baseRecipe->detalles->where('item_id', $modifier->item_id)->first();
        $qtyAjustada = $ingrediente->qty + ($modifier->quantity_change * $menuItem->quantity);

        // Registrar consumo ajustado
    }
}
```

#### **5. Validación de Integridad**

**Consumo Teórico vs Real:**

- Cada cierto tiempo (semanal), comparar:
  - **Teórico:** Lo que debió consumirse según ventas explotadas
  - **Real:** Conteo físico de inventario

```sql
-- Reporte de diferencias
SELECT
    item_id,
    SUM(CASE WHEN tipo = 'VENTA' THEN ABS(qty) ELSE 0 END) AS consumo_teorico,
    (stock_inicial - stock_final) AS consumo_real,
    ((stock_inicial - stock_final) - SUM(CASE WHEN tipo = 'VENTA' THEN ABS(qty) ELSE 0 END)) AS diferencia
FROM mov_inv
WHERE DATE(ts) BETWEEN '2025-10-01' AND '2025-10-31'
GROUP BY item_id;
```

**Causas de Diferencias:**
- Merma no registrada
- Robos
- Errores en recetas
- Consumo no documentado (pruebas, degustaciones)

#### **6. Estados de Implementación**

**FASE 1 (COMPRAS):**
- ✅ Leer consumo desde POS (sin explosión de recetas)
- ✅ Calcular promedio simple de items directamente vendidos
- ⚠️ NO explotar recetas aún (asumir items = menu_items)

**FASE 2 (PRODUCCIÓN):**
- ✅ Implementar explosión de recetas
- ✅ Registrar consumo teórico en mov_inv
- ✅ Servicio `RecipeExplosionService`

**FASE 3 (TRANSFERENCIAS):**
- ✅ Reporte de diferencias teórico vs real
- ✅ Alertas de merma excesiva

---

**Diferencias a Registrar:**
```sql
-- En recepcion_det agregar:
qty_ordenada NUMERIC(18,6),  -- Lo que se pidió
qty_recibida NUMERIC(18,6),  -- Lo que llegó
qty_rechazada NUMERIC(18,6), -- Lo que se rechazó
motivo_rechazo VARCHAR(100),
diferencia_costo NUMERIC(18,2), -- Si el precio cambió
```

### **1.5 Devoluciones a Proveedor**

**Tabla Propuesta:** `purchase_returns` (nueva)

```sql
CREATE TABLE selemti.purchase_returns (
    id BIGSERIAL PRIMARY KEY,
    folio VARCHAR(20) UNIQUE NOT NULL,  -- DEV-PROV-2025-001234
    purchase_order_id BIGINT NOT NULL REFERENCES selemti.purchase_orders(id),
    proveedor_id BIGINT NOT NULL REFERENCES selemti.cat_proveedores(id),
    sucursal_id BIGINT REFERENCES selemti.cat_sucursales(id),
    almacen_id BIGINT REFERENCES selemti.cat_almacenes(id),

    estado VARCHAR(20) DEFAULT 'BORRADOR',  -- BORRADOR, APROBADA, EN_TRANSITO, RECIBIDA_PROVEEDOR, NOTA_CREDITO, CERRADA
    motivo VARCHAR(100) NOT NULL,  -- DEFECTUOSO, CADUCADO, ERROR_PROVEEDOR, EXCESO, OTRO

    -- Totales
    total_items INT DEFAULT 0,
    total_devuelto NUMERIC(18,2) DEFAULT 0,

    -- Auditoría
    solicitado_por_user_id BIGINT REFERENCES users(id),
    solicitado_en TIMESTAMP DEFAULT NOW(),
    aprobado_por_user_id BIGINT REFERENCES users(id),
    aprobado_en TIMESTAMP,

    -- Logística
    guia_envio VARCHAR(50),
    transportista VARCHAR(100),
    fecha_envio DATE,
    fecha_recepcion_proveedor DATE,

    -- Financiero
    nota_credito_folio VARCHAR(50),
    monto_nota_credito NUMERIC(18,2),

    notas TEXT,
    meta JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE selemti.purchase_return_lines (
    id BIGSERIAL PRIMARY KEY,
    return_id BIGINT NOT NULL REFERENCES selemti.purchase_returns(id) ON DELETE CASCADE,
    purchase_order_line_id BIGINT REFERENCES selemti.purchase_order_lines(id),
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),

    qty_devuelta NUMERIC(18,6) NOT NULL,
    uom VARCHAR(10) NOT NULL,

    costo_unitario NUMERIC(18,6),
    costo_total_linea NUMERIC(18,2),

    lote VARCHAR(50),
    fecha_caducidad DATE,

    motivo_especifico TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Flujo de Devolución:**
```
BORRADOR  (almacén crea devolución)
  ↓
APROBADA  (gerente aprueba)
  ↓
EN_TRANSITO  (material enviado a proveedor)
  ↓
RECIBIDA_PROVEEDOR  (proveedor confirma recepción)
  ↓
NOTA_CREDITO  (nota de crédito emitida)
  ↓
CERRADA
```

**Movimiento en Kardex:**
```
tipo_mov = 'DEVOLUCION_PROVEEDOR'
ref_tipo = 'PURCHASE_RETURN'
ref_id = purchase_return_id
qty = -qty_devuelta  (negativo, sale del almacén)
```

---

## 🏭 FLUJO 2: PRODUCCIÓN INTERNA (COCINA CENTRAL)

### **Objetivo Operativo**
Producir internamente salsas, bases, masas, preparaciones que serán consumidas por sucursales.

### **Proceso Completo**

```
SUGERENCIA → SOLICITUD → CONSOLIDACIÓN → ORDEN → PRODUCCIÓN → DISTRIBUCIÓN → [DEVOLUCIÓN]
```

### **2.1 Sugerencias de Producción**

**Tabla Propuesta:** `production_suggestions` (nueva)

```sql
CREATE TABLE selemti.production_suggestions (
    id BIGSERIAL PRIMARY KEY,
    folio VARCHAR(20) UNIQUE NOT NULL,  -- PSP-2025-001234

    -- Producto a producir
    producto_final_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),
    receta_id BIGINT REFERENCES selemti.recetas(id),

    -- Destino
    sucursal_produccion_id BIGINT REFERENCES selemti.cat_sucursales(id),  -- Cocina central
    almacen_produccion_id BIGINT REFERENCES selemti.cat_almacenes(id),

    -- Demanda
    demanda_total NUMERIC(18,6) DEFAULT 0,  -- Suma de demanda de todas las sucursales
    batch_size_sugerido NUMERIC(18,6),
    uom VARCHAR(10),

    estado VARCHAR(20) DEFAULT 'PENDIENTE',  -- PENDIENTE, CONSOLIDADA, APROBADA, CONVERTIDA, RECHAZADA
    prioridad VARCHAR(20) DEFAULT 'NORMAL',

    -- Programación
    fecha_produccion_sugerida DATE,
    turno VARCHAR(20),  -- MATUTINO, VESPERTINO, NOCTURNO

    -- Costos
    costo_insumos_estimado NUMERIC(18,2),
    costo_mano_obra_estimado NUMERIC(18,2),
    costo_total_estimado NUMERIC(18,2),

    -- Auditoría
    sugerido_en TIMESTAMP DEFAULT NOW(),
    sugerido_por_user_id BIGINT REFERENCES users(id),
    consolidado_por_user_id BIGINT REFERENCES users(id),
    consolidado_en TIMESTAMP,
    convertido_a_order_id BIGINT REFERENCES selemti.production_orders(id),
    convertido_en TIMESTAMP,

    notas TEXT,
    meta JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE selemti.production_suggestion_demands (
    id BIGSERIAL PRIMARY KEY,
    suggestion_id BIGINT NOT NULL REFERENCES selemti.production_suggestions(id) ON DELETE CASCADE,

    -- Origen de la demanda
    sucursal_solicitante_id BIGINT REFERENCES selemti.cat_sucursales(id),
    almacen_destino_id BIGINT REFERENCES selemti.cat_almacenes(id),

    qty_solicitada NUMERIC(18,6) NOT NULL,
    stock_actual_sucursal NUMERIC(18,6),
    consumo_promedio_diario NUMERIC(18,6),
    dias_cobertura INT,

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE selemti.production_suggestion_ingredients (
    id BIGSERIAL PRIMARY KEY,
    suggestion_id BIGINT NOT NULL REFERENCES selemti.production_suggestions(id) ON DELETE CASCADE,
    insumo_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),

    qty_requerida NUMERIC(18,6) NOT NULL,
    uom VARCHAR(10),

    stock_actual NUMERIC(18,6),
    stock_suficiente BOOLEAN DEFAULT TRUE,

    costo_unitario NUMERIC(18,6),
    costo_total NUMERIC(18,2),

    created_at TIMESTAMP DEFAULT NOW()
);
```

**Flujo de Consolidación:**

1. **Sugerencias Individuales:**
   - Cada sucursal genera sugerencia de producción basada en su demanda local
   - Sistema calcula: `demanda_sucursal = max_qty - stock_actual`

2. **Consolidación Central:**
   - Cocina central agrupa sugerencias del mismo producto
   - Calcula batch size óptimo: `batch_total = SUM(demanda_sucursales) + buffer_seguridad`
   - Valida disponibilidad de insumos
   - Ajusta a batch size estándar de receta

3. **Validación:**
   ```php
   foreach ($ingredientes_receta as $ing) {
       $qty_necesaria = ($batch_total / $receta->rendimiento) * $ing->qty_por_unidad;
       $stock_disponible = StockCalculator::getCurrentStock($ing->item_id, $almacen_cocina);

       if ($stock_disponible < $qty_necesaria) {
           // Marcar ingrediente como insuficiente
           // Generar sugerencia de compra automática
       }
   }
   ```

### **2.2 Órdenes de Producción**

**Tabla Existente:** `selemti.production_orders` ✅
**Tablas Existentes:** `selemti.production_order_inputs`, `selemti.production_order_outputs` ✅

**Estados Actuales:**
```
BORRADOR → PLANIFICADA → EN_PROCESO → COMPLETADO → PAUSADA → CANCELADA
```

**Estados Propuestos (ampliados para cocina central):**

**CORE (Versión 1.0 - Mínimo Funcional):**
```
BORRADOR → PLANIFICADA → EN_PROCESO → TERMINADA → POSTEADA_A_INVENTARIO → CERRADA
```

**EXTENDIDOS (Versiones Futuras):**
```
BORRADOR
  ↓
PLANIFICADA  (programada en calendario de cocina)
  ↓
[LIBERADA_A_COCINA]  (mejora futura: insumos apartados, chef asignado)
  ↓
EN_PROCESO  (producción en curso)
  ↓
[PAUSADA]  (mejora futura: si se detiene temporalmente)
  ↓
TERMINADA  (producto terminado)
  ↓
[EN_VALIDACION_CALIDAD]  (mejora futura: QC verifica)
  ↓
[APROBADA_CALIDAD]  (mejora futura: QC aprobado)
  ↓
POSTEADA_A_INVENTARIO  ⚠️ CRÍTICO: entrada de PT, salida de insumos
  ↓
[LISTA_PARA_DISTRIBUIR]  (mejora futura: ready para transferencias)
  ↓
[EN_DISTRIBUCION]  (mejora futura: se están generando transferencias)
  ↓
CERRADA
```

**Nota:** Los estados entre `[]` son EXTENDIDOS. La implementación Fase 2 usará solo estados CORE.

**Campos Adicionales Necesarios:**
```sql
ALTER TABLE selemti.production_orders ADD COLUMN IF NOT EXISTS
    chef_responsable_id BIGINT REFERENCES users(id),
    validado_calidad_por_user_id BIGINT REFERENCES users(id),
    validado_calidad_en TIMESTAMP,
    rendimiento_real_pct NUMERIC(5,2),  -- % real vs esperado
    merma_real_pct NUMERIC(5,2),
    distribuido BOOLEAN DEFAULT FALSE;
```

### **2.3 Distribución a Sucursales**

Después de que la producción se completa:

1. Sistema genera **transferencias automáticas** basadas en demandas originales
2. Cada transferencia:
   - Origen: Almacén Cocina Central
   - Destino: Almacén Sucursal Solicitante
   - Qty: Demanda original de esa sucursal
   - Referencia: production_order_id

```sql
-- Automáticamente crear:
INSERT INTO transfer_cab (
    sucursal_origen_id,
    almacen_origen_id,
    sucursal_destino_id,
    almacen_destino_id,
    ref_tipo,
    ref_id,
    ...
)
SELECT
    production_order.sucursal_id,
    production_order.almacen_id,
    demand.sucursal_solicitante_id,
    demand.almacen_destino_id,
    'PRODUCTION_ORDER',
    production_order.id,
    ...
FROM production_suggestion_demands demand
WHERE suggestion_id = ...
```

### **2.4 Devoluciones de Producción**

**Tabla Propuesta:** `production_returns` (nueva)

```sql
CREATE TABLE selemti.production_returns (
    id BIGSERIAL PRIMARY KEY,
    folio VARCHAR(20) UNIQUE NOT NULL,  -- DEV-PROD-2025-001234
    production_order_id BIGINT NOT NULL REFERENCES selemti.production_orders(id),
    producto_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),

    sucursal_id BIGINT REFERENCES selemti.cat_sucursales(id),
    almacen_id BIGINT REFERENCES selemti.cat_almacenes(id),

    estado VARCHAR(20) DEFAULT 'REGISTRADA',  -- REGISTRADA, VALIDADA, POSTEADA, CERRADA
    tipo_devolucion VARCHAR(50) NOT NULL,  -- LOTE_RECHAZADO, MERMA_EXCESIVA, ERROR_RECETA, EXCESO_PRODUCCION

    qty_devuelta NUMERIC(18,6) NOT NULL,
    uom VARCHAR(10),

    -- Causas
    motivo TEXT NOT NULL,
    responsable VARCHAR(100),

    -- Financiero
    costo_perdido NUMERIC(18,2),
    recuperable BOOLEAN DEFAULT FALSE,

    -- Auditoría
    registrado_por_user_id BIGINT REFERENCES users(id),
    registrado_en TIMESTAMP DEFAULT NOW(),
    validado_por_user_id BIGINT REFERENCES users(id),
    validado_en TIMESTAMP,

    notas TEXT,
    meta JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

**Casos de Uso:**

1. **Lote Rechazado por Calidad:**
   - QC rechaza el lote completo o parcial
   - Se registra devolución tipo `LOTE_RECHAZADO`
   - No entra a inventario de PT
   - Se analiza causa raíz (insumo defectuoso, proceso incorrecto)

2. **Merma Excesiva:**
   - Merma real > merma esperada
   - Se registra la diferencia como devolución
   - Costo se registra como pérdida

3. **Exceso de Producción:**
   - Se produjo más de lo planeado
   - El excedente se marca como `EXCESO_PRODUCCION`
   - Puede reutilizarse o descartarse

**Movimiento en Kardex:**
```
tipo_mov = 'DEVOLUCION_PRODUCCION' o 'MERMA_PRODUCCION'
ref_tipo = 'PRODUCTION_RETURN'
ref_id = production_return_id
qty = -qty_devuelta  (negativo, sale o nunca entró)
```

---

## 🚚 FLUJO 3: TRANSFERENCIAS INTERNAS (REABASTECIMIENTO)

### **Objetivo Operativo**
Rebalancear inventario entre sucursales/almacenes para optimizar distribución.

### **Proceso Completo**

```
SUGERENCIA → SOLICITUD → APROBACIÓN → DESPACHO → TRÁNSITO → RECEPCIÓN → [DEVOLUCIÓN]
```

### **3.1 Sugerencias de Transferencia**

**Tabla Propuesta:** `transfer_suggestions` (nueva)

```sql
CREATE TABLE selemti.transfer_suggestions (
    id BIGSERIAL PRIMARY KEY,
    folio VARCHAR(20) UNIQUE NOT NULL,  -- PST-2025-001234

    -- Origen y Destino
    sucursal_origen_id BIGINT NOT NULL REFERENCES selemti.cat_sucursales(id),
    almacen_origen_id BIGINT REFERENCES selemti.cat_almacenes(id),
    sucursal_destino_id BIGINT NOT NULL REFERENCES selemti.cat_sucursales(id),
    almacen_destino_id BIGINT REFERENCES selemti.cat_almacenes(id),

    estado VARCHAR(20) DEFAULT 'PENDIENTE',  -- PENDIENTE, APROBADA, CONVERTIDA, RECHAZADA
    tipo VARCHAR(20) DEFAULT 'REBALANCEO',  -- URGENTE, REGULAR, REBALANCEO, EVENTO_ESPECIAL
    prioridad VARCHAR(20) DEFAULT 'NORMAL',

    -- Logística
    distancia_km NUMERIC(8,2),
    costo_envio_estimado NUMERIC(18,2),
    tiempo_transito_estimado_hrs INT,

    -- Totales
    total_items INT DEFAULT 0,
    valor_total_estimado NUMERIC(18,2),

    -- Auditoría
    sugerido_en TIMESTAMP DEFAULT NOW(),
    sugerido_por_user_id BIGINT REFERENCES users(id),
    aprobado_por_user_id BIGINT REFERENCES users(id),
    aprobado_en TIMESTAMP,
    convertido_a_transfer_id BIGINT REFERENCES selemti.transfer_cab(id),
    convertido_en TIMESTAMP,

    notas TEXT,
    meta JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE selemti.transfer_suggestion_lines (
    id BIGSERIAL PRIMARY KEY,
    suggestion_id BIGINT NOT NULL REFERENCES selemti.transfer_suggestions(id) ON DELETE CASCADE,
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),

    -- Stock y necesidad
    stock_actual_origen NUMERIC(18,6),
    stock_disponible_origen NUMERIC(18,6),  -- Disponible para transferir
    stock_min_origen NUMERIC(18,6),

    stock_actual_destino NUMERIC(18,6),
    stock_min_destino NUMERIC(18,6),
    stock_max_destino NUMERIC(18,6),

    -- Cantidades
    qty_sugerida NUMERIC(18,6) NOT NULL,
    qty_ajustada NUMERIC(18,6),
    uom VARCHAR(10),

    -- Justificación
    faltante_destino NUMERIC(18,6),
    excedente_origen NUMERIC(18,6),
    dias_cobertura_origen INT,
    dias_cobertura_destino INT,

    -- Costos
    costo_unitario NUMERIC(18,6),
    valor_linea NUMERIC(18,2),

    created_at TIMESTAMP DEFAULT NOW()
);
```

**Lógica de Sugerencias:**

```php
// Análisis de Rebalanceo Automático
foreach ($sucursales as $sucursal_destino) {
    foreach ($items_con_politica as $item) {
        $stock_destino = StockCalculator::getCurrentStock($item->id, $sucursal_destino->almacen_id);
        $policy_destino = StockPolicy::getPolicyFor($item->id, $sucursal_destino->id);

        if ($stock_destino < $policy_destino->min_qty) {
            $faltante = $policy_destino->max_qty - $stock_destino;

            // Buscar sucursales con excedente
            foreach ($sucursales_origen as $sucursal_origen) {
                if ($sucursal_origen->id == $sucursal_destino->id) continue;

                $stock_origen = StockCalculator::getCurrentStock($item->id, $sucursal_origen->almacen_id);
                $policy_origen = StockPolicy::getPolicyFor($item->id, $sucursal_origen->id);

                $excedente = $stock_origen - $policy_origen->max_qty;

                if ($excedente > 0) {
                    $qty_transferir = min($faltante, $excedente);

                    // Crear sugerencia de transferencia
                    TransferSuggestionLine::create([
                        'item_id' => $item->id,
                        'qty_sugerida' => $qty_transferir,
                        'faltante_destino' => $faltante,
                        'excedente_origen' => $excedente,
                        ...
                    ]);

                    break; // Ya encontró origen
                }
            }
        }
    }
}
```

### **3.2 Órdenes de Transferencia**

**Tabla Existente:** `selemti.transfer_cab` ✅
**Tabla Existente:** `selemti.transfer_det` ✅

**Estados Propuestos:**

**CORE (Versión 1.0 - Mínimo Funcional):**
```
SOLICITADA → APROBADA → DESPACHADA → RECIBIDA → POSTEADA_A_INVENTARIO → CERRADA
```

**EXTENDIDOS (Versiones Futuras):**
```
SOLICITADA
  ↓
APROBADA
  ↓
[PREPARANDO_EN_ORIGEN]  (mejora futura: picking en almacén origen)
  ↓
[LISTA_PARA_DESPACHO]  (mejora futura: preparación completa)
  ↓
DESPACHADA  (material salió de origen)
  ↓
[EN_TRANSITO]  (mejora futura: tracking en ruta)
  ↓
[ARRIBADA_A_DESTINO]  (mejora futura: llegó pero no recibida formalmente)
  ↓
[RECIBIDA_PARCIAL]  (mejora futura: si aplica recepción parcial)
  ↓
RECIBIDA  (recepción completa o única)
  ↓
POSTEADA_A_INVENTARIO  ⚠️ CRÍTICO: salida origen + entrada destino
  ↓
CERRADA
```

**Nota:** Los estados entre `[]` son EXTENDIDOS. La implementación Fase 3 usará solo estados CORE.

**Campos Adicionales Necesarios:**
```sql
ALTER TABLE selemti.transfer_cab ADD COLUMN IF NOT EXISTS
    preparado_por_user_id BIGINT REFERENCES users(id),
    preparado_en TIMESTAMP,
    despachado_por_user_id BIGINT REFERENCES users(id),
    despachado_en TIMESTAMP,
    transportista VARCHAR(100),
    guia_envio VARCHAR(50),
    vehiculo VARCHAR(50),
    conductor VARCHAR(100),
    fecha_salida TIMESTAMP,
    fecha_llegada_estimada TIMESTAMP,
    fecha_llegada_real TIMESTAMP,
    recibido_por_user_id BIGINT REFERENCES users(id),
    recibido_en TIMESTAMP,
    tiene_diferencias BOOLEAN DEFAULT FALSE;
```

### **3.3 Recepciones de Transferencia**

Usar la misma tabla `recepcion_cab` con:
- `ref_tipo = 'TRANSFER'`
- `ref_id = transfer_cab.id`

**Validaciones Específicas:**

1. **Verificar Cantidades:**
   ```sql
   SELECT
       td.item_id,
       td.qty AS qty_enviada,
       rd.qty AS qty_recibida,
       (rd.qty - td.qty) AS diferencia
   FROM transfer_det td
   LEFT JOIN recepcion_det rd ON rd.transfer_det_id = td.id
   WHERE td.transfer_id = ?
   HAVING diferencia != 0;
   ```

2. **Causas de Diferencias:**
   - Merma en tránsito
   - Robo/pérdida
   - Error en despacho
   - Daño durante transporte

3. **Conciliación:**
   - Si diferencia < 5%: aprobar automáticamente
   - Si diferencia >= 5%: requiere aprobación de gerencia
   - Si hay faltantes: generar reporte de investigación

### **3.4 Devoluciones de Transferencia**

**Tabla Propuesta:** `transfer_returns` (nueva)

```sql
CREATE TABLE selemti.transfer_returns (
    id BIGSERIAL PRIMARY KEY,
    folio VARCHAR(20) UNIQUE NOT NULL,  -- DEV-TRANS-2025-001234
    transfer_id BIGINT NOT NULL REFERENCES selemti.transfer_cab(id),

    -- Reversa del flujo original
    sucursal_origen_id BIGINT NOT NULL REFERENCES selemti.cat_sucursales(id),  -- Era destino
    almacen_origen_id BIGINT REFERENCES selemti.cat_almacenes(id),
    sucursal_destino_id BIGINT NOT NULL REFERENCES selemti.cat_sucursales(id),  -- Era origen
    almacen_destino_id BIGINT REFERENCES selemti.cat_almacenes(id),

    estado VARCHAR(20) DEFAULT 'SOLICITADA',  -- SOLICITADA, APROBADA, EN_TRANSITO, RECIBIDA, CERRADA
    motivo VARCHAR(100) NOT NULL,  -- NO_REQUERIDO, DEFECTUOSO, ERROR_ENVIO, EXCESO

    -- Totales
    total_items INT DEFAULT 0,
    valor_total NUMERIC(18,2),

    -- Auditoría
    solicitado_por_user_id BIGINT REFERENCES users(id),
    solicitado_en TIMESTAMP DEFAULT NOW(),
    aprobado_por_user_id BIGINT REFERENCES users(id),
    aprobado_en TIMESTAMP,

    notas TEXT,
    meta JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE selemti.transfer_return_lines (
    id BIGSERIAL PRIMARY KEY,
    return_id BIGINT NOT NULL REFERENCES selemti.transfer_returns(id) ON DELETE CASCADE,
    transfer_det_id BIGINT REFERENCES selemti.transfer_det(id),
    item_id VARCHAR(20) NOT NULL REFERENCES selemti.items(id),

    qty_devuelta NUMERIC(18,6) NOT NULL,
    uom VARCHAR(10),

    motivo_especifico TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Flujo de Devolución:**
```
SOLICITADA  (sucursal destino solicita devolver)
  ↓
APROBADA  (origen acepta devolución)
  ↓
EN_TRANSITO  (material regresando)
  ↓
RECIBIDA  (origen recibe material)
  ↓
POSTEADA  (inventario actualizado)
  ↓
CERRADA
```

---

## 🔍 TRAZABILIDAD COMPLETA (KARDEX)

### **Tabla Central:** `selemti.mov_inv` (Kardex)

Cada operación debe generar movimientos en Kardex:

```sql
-- Tipos de Movimiento Existentes + Propuestos
COMPRA                    -- Entrada por compra
DEVOLUCION_PROVEEDOR      -- Salida por devolución a proveedor
PRODUCCION_ENTRADA        -- Entrada de producto terminado
PRODUCCION_SALIDA         -- Salida de insumos para producción
DEVOLUCION_PRODUCCION     -- Reversión de producción
MERMA_PRODUCCION          -- Merma en producción
TRANSFERENCIA_SALIDA      -- Salida por transferencia
TRANSFERENCIA_ENTRADA     -- Entrada por transferencia
DEVOLUCION_TRANSFER_SALIDA
DEVOLUCION_TRANSFER_ENTRADA
AJUSTE_INVENTARIO         -- Conteo físico
VENTA                     -- Consumo POS
```

**Campos en mov_inv:**
```sql
id BIGSERIAL PRIMARY KEY,
item_id VARCHAR(20) NOT NULL,
almacen_id BIGINT NOT NULL,
tipo VARCHAR(50) NOT NULL,
qty NUMERIC(18,6) NOT NULL,  -- Positivo = entrada, Negativo = salida
uom VARCHAR(10),
costo_unitario NUMERIC(18,6),
ref_tipo VARCHAR(50),  -- PURCHASE_ORDER, PRODUCTION_ORDER, TRANSFER, etc.
ref_id BIGINT,
lote VARCHAR(50),
ts TIMESTAMP DEFAULT NOW(),
user_id BIGINT REFERENCES users(id),
notas TEXT
```

**Ejemplo de Flujo Completo:**

```sql
-- 1. Sugerencia de Compra → Solicitud → Orden → Recepción
INSERT INTO mov_inv (tipo, qty, ref_tipo, ref_id) VALUES
('COMPRA', 100, 'PURCHASE_ORDER', 12345);

-- 2. Producción: Salida de insumos
INSERT INTO mov_inv (tipo, qty, ref_tipo, ref_id) VALUES
('PRODUCCION_SALIDA', -50, 'PRODUCTION_ORDER', 789);  -- Harina
('PRODUCCION_SALIDA', -10, 'PRODUCTION_ORDER', 789);  -- Azúcar

-- 3. Producción: Entrada de producto terminado
INSERT INTO mov_inv (tipo, qty, ref_tipo, ref_id) VALUES
('PRODUCCION_ENTRADA', 30, 'PRODUCTION_ORDER', 789);  -- Masa

-- 4. Transferencia a sucursal
INSERT INTO mov_inv (tipo, qty, ref_tipo, ref_id) VALUES
('TRANSFERENCIA_SALIDA', -20, 'TRANSFER', 456);  -- Salida de cocina central
('TRANSFERENCIA_ENTRADA', 20, 'TRANSFER', 456);  -- Entrada en sucursal

-- 5. Devolución a proveedor
INSERT INTO mov_inv (tipo, qty, ref_tipo, ref_id) VALUES
('DEVOLUCION_PROVEEDOR', -5, 'PURCHASE_RETURN', 999);
```

---

## 📡 API ENDPOINTS

### **Compras**
```
GET    /api/purchasing/suggestions              # Listar sugerencias
POST   /api/purchasing/suggestions/generate     # Generar automáticas
POST   /api/purchasing/suggestions/{id}/approve # Aprobar
POST   /api/purchasing/suggestions/{id}/convert # Convertir a request

GET    /api/purchasing/requests                 # Listar solicitudes
POST   /api/purchasing/requests                 # Crear manual
POST   /api/purchasing/requests/{id}/quote      # Solicitar cotización
POST   /api/purchasing/requests/{id}/approve    # Aprobar

GET    /api/purchasing/orders                   # Listar órdenes
POST   /api/purchasing/orders                   # Crear desde request
POST   /api/purchasing/orders/{id}/send         # Enviar a proveedor
POST   /api/purchasing/orders/{id}/confirm      # Confirmar recepción

GET    /api/purchasing/returns                  # Listar devoluciones
POST   /api/purchasing/returns                  # Crear devolución
POST   /api/purchasing/returns/{id}/approve     # Aprobar
```

### **Producción**
```
GET    /api/production/suggestions              # Listar sugerencias
POST   /api/production/suggestions/generate     # Generar automáticas
POST   /api/production/suggestions/{id}/consolidate  # Consolidar demandas
POST   /api/production/suggestions/{id}/validate-ingredients  # Validar insumos
POST   /api/production/suggestions/{id}/convert # Convertir a orden

GET    /api/production/orders                   # Listar órdenes
POST   /api/production/orders                   # Crear
POST   /api/production/orders/{id}/release      # Liberar a cocina
POST   /api/production/orders/{id}/start        # Iniciar producción
POST   /api/production/orders/{id}/complete     # Completar
POST   /api/production/orders/{id}/validate-quality  # QC
POST   /api/production/orders/{id}/post         # Postear a inventario

GET    /api/production/returns                  # Listar devoluciones
POST   /api/production/returns                  # Registrar merma/rechazo
```

### **Transferencias**
```
GET    /api/transfers/suggestions               # Listar sugerencias
POST   /api/transfers/suggestions/generate      # Generar automáticas
POST   /api/transfers/suggestions/{id}/approve  # Aprobar
POST   /api/transfers/suggestions/{id}/convert  # Convertir a orden

GET    /api/transfers/orders                    # Listar transferencias
POST   /api/transfers/orders                    # Crear
POST   /api/transfers/orders/{id}/prepare       # Preparar en origen
POST   /api/transfers/orders/{id}/dispatch      # Despachar
POST   /api/transfers/orders/{id}/receive       # Recibir en destino

GET    /api/transfers/returns                   # Listar devoluciones
POST   /api/transfers/returns                   # Crear devolución
```

### **Recepciones**
```
GET    /api/inventory/receptions                # Listar recepciones
POST   /api/inventory/receptions                # Crear recepción
POST   /api/inventory/receptions/{id}/validate  # Validar cantidades
POST   /api/inventory/receptions/{id}/post      # Postear a inventario
```

---

## 📦 CATÁLOGOS REQUERIDOS

### **Existentes (Verificados en BD)**
- `selemti.cat_proveedores` ✅
- `selemti.cat_sucursales` ✅
- `selemti.cat_almacenes` ✅
- `selemti.unidades_medida` ✅
- `selemti.items` ✅
- `selemti.recetas` ✅
- `users` ✅

### **Nuevos o Ampliados**
- **Stock Policies:** `selemti.stock_policy` (ya existe, verificar campos)
  - Necesita: `reorder_qty`, `lead_time_days`, `safety_stock`

- **Motivos de Devolución:** Pueden ser enums o tabla
  ```sql
  CREATE TABLE selemti.cat_motivos_devolucion (
      id SERIAL PRIMARY KEY,
      codigo VARCHAR(20) UNIQUE,
      descripcion VARCHAR(100),
      tipo VARCHAR(20),  -- COMPRA, PRODUCCION, TRANSFERENCIA
      requiere_nota_credito BOOLEAN DEFAULT FALSE,
      activo BOOLEAN DEFAULT TRUE
  );
  ```

---

## 🛠️ SERVICIOS COMPARTIDOS

### **1. StockCalculatorService**

```php
namespace App\Services\Inventory;

class StockCalculatorService
{
    /**
     * Obtener stock actual de un item en un almacén
     */
    public function getCurrentStock(string $itemId, ?int $almacenId = null): float
    {
        return DB::connection('pgsql')
            ->table('selemti.vw_stock_actual')
            ->where('item_id', $itemId)
            ->when($almacenId, fn($q) => $q->where('almacen_id', $almacenId))
            ->sum('qty');
    }

    /**
     * Consumo promedio diario
     */
    public function getAverageDailyConsumption(
        string $itemId,
        int $almacenId,
        int $days = 7
    ): float {
        $startDate = now()->subDays($days);

        $totalConsumed = DB::connection('pgsql')
            ->table('selemti.mov_inv')
            ->where('item_id', $itemId)
            ->where('almacen_id', $almacenId)
            ->where('tipo', 'VENTA')  // o el tipo de salida que uses
            ->where('ts', '>=', $startDate)
            ->sum('qty');  // Tomar valor absoluto

        return abs($totalConsumed) / $days;
    }

    /**
     * Días de cobertura
     */
    public function getDaysOfCoverage(string $itemId, int $almacenId): int
    {
        $stockActual = $this->getCurrentStock($itemId, $almacenId);
        $consumoPromedio = $this->getAverageDailyConsumption($itemId, $almacenId);

        if ($consumoPromedio <= 0) {
            return 999;  // Stock infinito si no hay consumo
        }

        return (int) floor($stockActual / $consumoPromedio);
    }

    /**
     * Demanda proyectada
     */
    public function getProjectedDemand(
        string $itemId,
        int $almacenId,
        int $daysToProject = 7
    ): float {
        $consumoPromedio = $this->getAverageDailyConsumption($itemId, $almacenId);
        return $consumoPromedio * $daysToProject;
    }
}
```

### **2. StockPolicyService**

```php
namespace App\Services\Inventory;

class StockPolicyService
{
    /**
     * Obtener política de stock para item/sucursal
     */
    public function getPolicyFor(string $itemId, int $sucursalId): ?StockPolicy
    {
        return StockPolicy::where('item_id', $itemId)
            ->where('sucursal_id', $sucursalId)
            ->where('activo', true)
            ->first();
    }

    /**
     * ¿Debe reordenarse?
     */
    public function shouldReorder(string $itemId, int $almacenId): bool
    {
        $stockActual = app(StockCalculatorService::class)->getCurrentStock($itemId, $almacenId);
        $almacen = Almacen::find($almacenId);
        $policy = $this->getPolicyFor($itemId, $almacen->sucursal_id);

        if (!$policy) {
            return false;
        }

        return $stockActual < $policy->min_qty;
    }

    /**
     * Cantidad a reordenar
     */
    public function getReorderQuantity(string $itemId, int $almacenId): float
    {
        $stockActual = app(StockCalculatorService::class)->getCurrentStock($itemId, $almacenId);
        $almacen = Almacen::find($almacenId);
        $policy = $this->getPolicyFor($itemId, $almacen->sucursal_id);

        if (!$policy) {
            return 0;
        }

        return $policy->reorder_qty ?? ($policy->max_qty - $stockActual);
    }
}
```

---

## ✅ RESUMEN DE DECISIONES TÉCNICAS

### **Tablas a Crear (Nuevas)**
1. `purchase_suggestions` + `purchase_suggestion_lines`
2. `production_suggestions` + `production_suggestion_demands` + `production_suggestion_ingredients`
3. `transfer_suggestions` + `transfer_suggestion_lines`
4. `purchase_returns` + `purchase_return_lines`
5. `production_returns`
6. `transfer_returns` + `transfer_return_lines`

### **Tablas Existentes a Usar**
1. `purchase_requests` + `purchase_request_lines` ✅
2. `purchase_orders` + `purchase_order_lines` ✅
3. `production_orders` + `production_order_inputs/outputs` ✅
4. `transfer_cab` + `transfer_det` ✅
5. `recepcion_cab` + `recepcion_det` ✅
6. `mov_inv` (Kardex) ✅

### **Tablas Existentes a Ampliar**
- `purchase_requests`: Agregar `fecha_requerida`, `almacen_destino_id`, `urgente`
- `purchase_orders`: Estados ampliados
- `production_orders`: Agregar `chef_responsable_id`, `rendimiento_real_pct`, campos de QC
- `transfer_cab`: Agregar campos logísticos (transportista, guía, fechas, responsables)

### **Modelos Laravel**
**Nuevos:**
- `PurchaseSuggestion`, `PurchaseSuggestionLine`
- `ProductionSuggestion`, `ProductionSuggestionDemand`, `ProductionSuggestionIngredient`
- `TransferSuggestion`, `TransferSuggestionLine`
- `PurchaseReturn`, `PurchaseReturnLine`
- `ProductionReturn`
- `TransferReturn`, `TransferReturnLine`

**Existentes (usar):**
- `PurchaseRequest`, `PurchaseRequestLine` ✅
- `PurchaseOrder`, `PurchaseOrderLine` ✅
- `ProductionOrder` ✅
- `Transfer` (de transfer_cab), `TransferLine` (de transfer_det)
- `Reception` (de recepcion_cab), `ReceptionLine` (de recepcion_det)

### **Servicios**
- `PurchaseSuggestionService`
- `ProductionSuggestionService`
- `TransferSuggestionService`
- `StockCalculatorService` (compartido)
- `StockPolicyService` (compartido)

---

## 📊 TABLA DE TRAZABILIDAD: ORIGEN → RESULTADO → AFECTA INVENTARIO

Esta tabla resume la relación entre documentos y su impacto en el Kardex (`selemti.mov_inv`).

| # | Documento Origen | Documento Resultado | Genera mov_inv | Tipo mov_inv | Qty | Notas |
|---|------------------|---------------------|:--------------:|--------------|-----|-------|
| **FLUJO COMPRAS** |
| 1 | `purchase_suggestion` | `purchase_request` | ❌ No | - | - | Solo planificación |
| 2 | `purchase_request` | `purchase_order` | ❌ No | - | - | Solicitud pendiente |
| 3 | `purchase_order` | `recepcion_cab` | ✅ **Sí** | `COMPRA` | **+** | **INMUTABLE** |
| 4 | `purchase_order` | `purchase_return` | ✅ **Sí** | `DEVOLUCION_PROVEEDOR` | **-** | Salida del almacén |
| **FLUJO PRODUCCIÓN** |
| 5 | `production_suggestion` | `production_order` | ❌ No | - | - | Solo planificación |
| 6 | `production_order` (inputs) | - | ✅ **Sí** | `PRODUCCION_SALIDA` | **-** | Sale insumos |
| 7 | `production_order` (outputs) | - | ✅ **Sí** | `PRODUCCION_ENTRADA` | **+** | Entra PT |
| 8 | `production_order` | `transfer_cab` (distribución) | ✅ **Sí** | `TRANSFERENCIA_SALIDA` / `TRANSFERENCIA_ENTRADA` | **-** / **+** | Automático |
| 9 | `production_order` | `production_return` | ✅ **Sí** | `MERMA_PRODUCCION` o `DEVOLUCION_PRODUCCION` | **-** | Merma/rechazo |
| **FLUJO TRANSFERENCIAS** |
| 10 | `transfer_suggestion` | `transfer_cab` | ❌ No | - | - | Solo planificación |
| 11 | `transfer_cab` | - | ✅ **Sí** (doble) | `TRANSFERENCIA_SALIDA` (origen) + `TRANSFERENCIA_ENTRADA` (destino) | **-** / **+** | **2 movimientos** |
| 12 | `transfer_cab` | `transfer_return` | ✅ **Sí** (doble) | `DEVOLUCION_TRANSFER_SALIDA` + `DEVOLUCION_TRANSFER_ENTRADA` | **+** / **-** | Reversa del original |
| **OTROS MOVIMIENTOS** |
| 13 | Conteo físico | - | ✅ **Sí** | `AJUSTE_INVENTARIO` | **+** o **-** | Corrección manual |
| 14 | Venta POS | - | ✅ **Sí** | `VENTA` | **-** | Desde explosión de receta |
| 15 | Merma detectada | - | ✅ **Sí** | `MERMA` | **-** | Pérdida documentada |

### **Reglas de Posteo a Inventario**

1. **Solo documentos POSTEADOS afectan `mov_inv`**
   - Estados `BORRADOR`, `PENDIENTE`, `APROBADA` NO generan movimientos
   - Estado `POSTEADA_A_INVENTARIO` genera movimientos **DEFINITIVOS**

2. **Movimientos en Pares (Transferencias)**
   - Una transferencia genera 2 movimientos:
     - Origen: `TRANSFERENCIA_SALIDA` (qty negativa)
     - Destino: `TRANSFERENCIA_ENTRADA` (qty positiva)
   - Mismo `ref_tipo='TRANSFER'`, mismo `ref_id`, mismos `item_id` y `qty` (invertida)

3. **Campos Obligatorios en mov_inv**
   ```sql
   INSERT INTO selemti.mov_inv (
       item_id,           -- ✅ Obligatorio
       almacen_id,        -- ✅ Obligatorio
       tipo,              -- ✅ Obligatorio (ver tipos arriba)
       qty,               -- ✅ Obligatorio (+ entrada, - salida)
       uom,               -- ✅ Obligatorio
       costo_unitario,    -- ✅ Requerido para valuación
       ref_tipo,          -- ✅ Obligatorio (nombre de la tabla origen)
       ref_id,            -- ✅ Obligatorio (ID del documento origen)
       lote,              -- Opcional (trazabilidad)
       ts,                -- ✅ Obligatorio (timestamp del movimiento)
       user_id,           -- ✅ Obligatorio (quién lo registró)
       notas              -- Opcional
   ) VALUES (...);
   ```

4. **Inmutabilidad**
   - Una vez insertado en `mov_inv`, **JAMÁS** se ejecuta `UPDATE` o `DELETE`
   - Correcciones se hacen con **movimientos compensatorios**

5. **Auditoría**
   - Todos los `INSERT` a `mov_inv` deben incluir `user_id` del responsable
   - Tabla de auditoría puede trackear cada posteo: `audit_log.action = 'POST_TO_INVENTORY'`

### **Ejemplo de Flujo Completo con Trazabilidad**

```sql
-- 1. Sugerencia de Compra (NO afecta inventario)
INSERT INTO selemti.purchase_suggestions (folio, estado, ...) VALUES ('PSC-001', 'PENDIENTE', ...);

-- 2. Convertir a Solicitud (NO afecta inventario)
INSERT INTO selemti.purchase_requests (folio, estado, ...) VALUES ('REQ-001', 'APROBADA', ...);
UPDATE selemti.purchase_suggestions SET estado = 'CONVERTIDA', convertido_a_request_id = 123;

-- 3. Crear Orden (NO afecta inventario)
INSERT INTO selemti.purchase_orders (folio, estado, ...) VALUES ('PO-001', 'APROBADA', ...);

-- 4. Recibir Material (✅ AFECTA INVENTARIO)
INSERT INTO selemti.recepcion_cab (folio, estado, ref_tipo, ref_id, ...)
VALUES ('REC-001', 'POSTEADA_A_INVENTARIO', 'PURCHASE_ORDER', 456, ...);

-- 5. POSTEAR A KARDEX (INMUTABLE)
INSERT INTO selemti.mov_inv (tipo, ref_tipo, ref_id, item_id, almacen_id, qty, ts, user_id)
VALUES
    ('COMPRA', 'PURCHASE_ORDER', 456, 'ITEM001', 10, 100.00, NOW(), 5),
    ('COMPRA', 'PURCHASE_ORDER', 456, 'ITEM002', 10, 50.00, NOW(), 5);

-- 6. Si hay error: crear AJUSTE (NO editar el original)
INSERT INTO selemti.mov_inv (tipo, ref_tipo, ref_id, item_id, almacen_id, qty, ts, user_id, notas)
VALUES ('AJUSTE_INVENTARIO', 'MANUAL_ADJUSTMENT', NULL, 'ITEM001', 10, -5.00, NOW(), 5, 'Corrección recepción REC-001');
```

---

## 🎯 PRÓXIMOS PASOS

**✅ DOCUMENTO APROBADO PARA IMPLEMENTACIÓN FASE 1**

### **Checklist de Aprobación Completado:**

- ✅ Plan de implementación por fases (COMPRAS → PRODUCCIÓN → TRANSFERENCIAS)
- ✅ Estados clasificados en CORE vs EXTENDIDO para cada flujo
- ✅ Regla crítica POSTEADA_A_INVENTARIO documentada (inmutabilidad)
- ✅ Configuración parametrizable (no hardcoded)
- ✅ Integración POS/VENTA documentada (con explosión de recetas)
- ✅ Tabla de trazabilidad completa (origen → resultado → mov_inv)
- ✅ Todas las tablas nuevas en esquema `selemti`
- ✅ Alineación con nombres de columnas existentes

### **Próximos Pasos - Implementación Fase 1 (COMPRAS):**

#### **Sprint 1.1: Sugerencias de Compra (3-5 días)**
1. Crear migrations:
   - `create_purchase_suggestions_table.php`
   - `create_purchase_suggestion_lines_table.php`
   - `alter_purchase_requests_add_fields.php`
2. Crear modelos Laravel:
   - `PurchaseSuggestion.php`
   - `PurchaseSuggestionLine.php`
3. Implementar servicios:
   - `StockCalculatorService.php`
   - `StockPolicyService.php`
   - `PurchaseSuggestionService.php`
4. Crear endpoints API:
   - `GET /api/purchasing/suggestions`
   - `POST /api/purchasing/suggestions/generate`
   - `POST /api/purchasing/suggestions/{id}/approve`
   - `POST /api/purchasing/suggestions/{id}/convert`
5. Crear command:
   - `php artisan purchasing:generate-suggestions`
6. Tests unitarios

#### **Sprint 1.2: Órdenes y Recepciones (4-6 días)**
7. Ampliar migrations existentes
8. Implementar `PurchaseOrderService` y `ReceptionService`
9. Endpoints para estados de órdenes
10. Validación de diferencias en recepciones
11. Posteo a `mov_inv`
12. Tests de integración

#### **Sprint 1.3: Devoluciones (3-4 días)**
13. Crear migrations para `purchase_returns`
14. Modelo `PurchaseReturn`
15. Servicio `PurchaseReturnService`
16. Endpoints API
17. Movimientos compensatorios en Kardex
18. Tests E2E completos

### **Criterio de Éxito Fase 1:**
- ✅ Generación automática de sugerencias de compra
- ✅ Conversión completa: Sugerencia → Request → Order → Recepción → mov_inv
- ✅ Devoluciones a proveedor funcionando
- ✅ Ningún mov_inv editado/borrado (100% inmutables)
- ✅ Coverage de tests > 80%

---

**Fin del Documento de Diseño v2.1**

**🚀 APROBADO - Listo para comenzar implementación Sprint 1.1**
