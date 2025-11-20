# MÓDULO: INVENTARIO

**Última actualización**: 31 de octubre de 2025  
**Responsable**: Equipo TerrenaLaravel  
**Prioridad**: 🔴 CRÍTICO

---

## 1. RESUMEN EJECUTIVO

### 1.1 Propósito del Módulo
El módulo de Inventario es uno de los componentes centrales del sistema TerrenaLaravel, encargado de gestionar todos los aspectos relacionados con productos, materias primas y suministros del negocio. Incluye funcionalidades para dar de alta ítems, recibir mercancía, gestionar lotes y caducidades, realizar conteos físicos y transferencias internas. El sistema implementa **FEFO (First Expire First Out)** para la gestión de inventario por caducidad.

### 1.2 Estado Actual
| Aspecto | Completitud | Estado |
|---------|-------------|--------|
| **Backend** | 70% | ✅ Core funcional |
| **Frontend** | 70% | ✅ Funcional, necesita polish |
| **API REST** | 75% | ✅ Endpoints principales OK |
| **Base de Datos** | 90% | ✅ Normalizada (Phases 2.1-2.4) |
| **Testing** | 30% | 🔴 Cobertura baja |
| **Documentación** | 85% | ✅ Completa |

**Nivel General de Completitud**: **70%** - Funcional pero necesita refinamiento UX

### 1.3 Criticidad
- **Impacto en negocio**: CRÍTICO - Base de operaciones diarias
- **Dependencias**: Compras, Producción, Recetas, POS
- **Usuarios afectados**: Gerentes, almacenistas, operadores

---

## 2. ESTADO ACTUAL

### 2.1 Backend

#### 2.1.1 Modelos Implementados
```php
✅ Item.php                    // Gestión general de ítems/insumos
✅ InventoryCount.php          // Gestión de conteos físicos
✅ InventoryCountLine.php      // Líneas de conteo
✅ Insumo.php                  // Legacy (mantener compatibilidad)
```

**Relaciones Implementadas**:
- ✅ `Item` → `Category` (belongsTo)
- ✅ `Item` → `Unit` (belongsTo para UOM base)
- ✅ `Item` → `ItemVendor` (hasMany - proveedores asociados)
- ✅ `Item` → `ItemUom` (hasMany - presentaciones)
- ✅ `Item` → `PurchaseOrderLine` (hasMany)
- ✅ `Item` → `RecipeIngredient` (hasMany)
- ✅ `InventoryCount` → `Warehouse` (belongsTo)
- ✅ `InventoryCount` → `InventoryCountLine` (hasMany)

**Campos Clave**:
```sql
items:
  - id (PK)
  - code (CAT-SUB-#####) // Auto-generado
  - name
  - description
  - category_id (FK)
  - base_unit_id (FK)
  - stock_min, stock_max
  - is_active
  - created_by, updated_by
  - timestamps
```

#### 2.1.2 Servicios Implementados
```php
✅ Inventory/InventoryCountService.php   // Gestión de conteos
✅ Inventory/ReceivingService.php        // Recepciones
✅ PosConsumptionService.php             // Consumo POS
✅ ProductionService.php                 // Producción
✅ CostingService.php                    // Costos (básico)
✅ TransferService.php                   // Transferencias
```

**InventoryCountService - Funcionalidades**:
- `createCount()` - Crear conteo físico (estado: BORRADOR)
- `startCount()` - Iniciar proceso (estado: EN_PROCESO)
- `captureLines()` - Capturar conteos físicos
- `calculateVariances()` - Calcular diferencias sistema vs físico
- `adjustInventory()` - Generar ajustes automáticos en kardex (estado: AJUSTADO)
- `generateReport()` - Reporte de exactitud

**ReceivingService - Funcionalidades**:
- `createReception()` - Registrar recepción con FEFO
- `validateQuality()` - Validación de temperatura, evidencias
- `postToInventory()` - Postear movimientos a kardex
- `createPriceSnapshot()` - Snapshot de costo al recibir
- `linkToPurchaseOrder()` - Asociar a orden de compra

#### 2.1.3 Funcionalidades Completadas
- ✅ **Recepciones con FEFO**: First Expire First Out implementado
- ✅ **Movimientos de inventario**: Kardex completo con trazabilidad
- ✅ **Conteos físicos**: Workflow 4 estados (BORRADOR → EN_PROCESO → REVISIÓN → AJUSTADO)
- ✅ **Costo unitario "a fecha"**: Función PostgreSQL `fn_item_unit_cost_at(item_id, fecha)`
- ✅ **Vista de precios vigentes**: `vw_item_last_price`, `vw_item_last_price_pref`
- ✅ **Control de lotes y caducidades**: Tabla `batches` con alertas
- ✅ **Sistema de alertas**: Stock bajo, caducidad próxima, stock cero
- ✅ **Panel orquestador**: Dashboard centralizado de inventario

#### 2.1.4 Funcionalidades Pendientes
- ❌ **OCR para caducidades**: Leer lote/fecha desde foto
- ⚠️ **Versionado automático de recetas**: Al cambiar costos
- ❌ **Simulador de impacto de costos**: Preview antes de ajustar
- ❌ **Mobile barcode scanning**: Escaneo de códigos desde app móvil
- ⚠️ **FEFO avanzado**: Control automático de rotación en picking

---

### 2.2 Frontend

#### 2.2.1 Componentes Livewire Implementados
```
✅ Inventory/ItemsManage.php           // Gestión de ítems con filtros
✅ Inventory/InsumoCreate.php          // Creación de insumos
✅ Inventory/ReceptionsIndex.php       // Listado de recepciones
✅ Inventory/ReceptionCreate.php       // Nueva recepción (modal)
✅ Inventory/ReceptionDetail.php       // Detalle de recepción
✅ Inventory/LotsIndex.php             // Lotes y caducidades
✅ Inventory/AlertsList.php            // Dashboard de alertas
✅ InventoryCount/Index.php            // Listado de conteos
✅ InventoryCount/Create.php           // Crear conteo
✅ InventoryCount/Capture.php          // Captura móvil/desktop
✅ InventoryCount/Review.php           // Revisión y ajustes
✅ InventoryCount/Detail.php           // Vista detalle
✅ Inventory/PhysicalCounts.php        // Conteos físicos
✅ Inventory/OrquestadorPanel.php      // Panel de orquestación
```

#### 2.2.2 Vistas Blade Implementadas
```
✅ resources/views/inventario.blade.php                  // Vista principal
✅ resources/views/livewire/inventory/items-manage.blade.php
✅ resources/views/livewire/inventory/insumo-create.blade.php
✅ resources/views/livewire/inventory/receptions-index.blade.php
✅ resources/views/livewire/inventory/reception-create.blade.php
✅ resources/views/livewire/inventory/reception-detail.blade.php
✅ resources/views/livewire/inventory/lots-index.blade.php
✅ resources/views/livewire/inventory/alerts-list.blade.php
✅ resources/views/livewire/inventory-count/*.blade.php  // Todas las vistas de conteo
```

#### 2.2.3 Funcionalidades Frontend Completadas
- ✅ **Listado con filtros avanzados**: Por categoría, almacén, estado, proveedor
- ✅ **Formularios de creación/edición**: Con validación básica
- ✅ **Componentes reactivos Livewire**: Actualizaciones en tiempo real
- ✅ **UI para conteos físicos**: Workflow visual de 4 estados
- ✅ **Dashboard de alertas**: Chips con códigos de color por criticidad
- ✅ **Layout responsivo**: Bootstrap 5 + Tailwind CSS

#### 2.2.4 Funcionalidades Frontend Pendientes
- ⚠️ **Validación inline mejorada**: Mensajes específicos por campo
- ❌ **Wizard de alta en 2 pasos**: (1) Datos maestros, (2) Presentaciones/Proveedor
- ❌ **Mobile-first para conteos**: UI optimizada para tablets en almacén
- ❌ **Arrastrar y soltar adjuntos**: Multiple file upload con preview
- ⚠️ **Autosuggest de nombres**: Normalización automática de nombres
- ❌ **Preview de código CAT-SUB**: Vista previa antes de guardar

---

### 2.3 API REST

#### 2.3.1 Endpoints Implementados

**Gestión de Items**:
```http
✅ GET    /api/inventory/items              // Listado con filtros
✅ POST   /api/inventory/items              // Crear ítem
✅ GET    /api/inventory/items/{id}         // Detalle ítem
✅ PUT    /api/inventory/items/{id}         // Actualizar ítem
✅ DELETE /api/inventory/items/{id}         // Eliminar ítem (soft delete)
```

**Stock y Movimientos**:
```http
✅ GET    /api/inventory/stock                    // Stock por ítem
✅ GET    /api/inventory/stock/list               // Lista completa de stock
✅ POST   /api/inventory/movements                // Crear movimiento manual
✅ GET    /api/inventory/items/{id}/kardex        // Kardex histórico
✅ GET    /api/inventory/items/{id}/batches       // Lotes del ítem
```

**Proveedores y Precios**:
```http
✅ GET    /api/inventory/items/{id}/vendors       // Proveedores asociados
✅ POST   /api/inventory/items/{id}/vendors       // Asociar proveedor
✅ POST   /api/inventory/prices                   // Registrar precio histórico
✅ GET    /api/inventory/items/{id}/cost-history  // Historial de costos
```

**Conteos Físicos**:
```http
✅ GET    /api/inventory/counts                   // Listado de conteos
✅ POST   /api/inventory/counts                   // Crear conteo
✅ PUT    /api/inventory/counts/{id}/start        // Iniciar conteo
✅ POST   /api/inventory/counts/{id}/lines        // Capturar líneas
✅ PUT    /api/inventory/counts/{id}/finalize     // Finalizar y ajustar
```

#### 2.3.2 Autenticación y Permisos
Todos los endpoints requieren:
- ✅ `Authorization: Bearer {token}` (Sanctum)
- ✅ Permisos específicos por acción (ver sección 2.5)

#### 2.3.3 Contratos API (Ejemplos)

**POST /api/inventory/items**:
```json
{
  "name": "Harina de trigo kg",
  "category_id": 5,
  "base_unit_id": 2,
  "stock_min": 50,
  "stock_max": 200,
  "description": "Harina uso general"
}
```

**Response**:
```json
{
  "id": 123,
  "code": "CAT05-SUB01-00123",
  "name": "Harina de trigo kg",
  "category": { "id": 5, "name": "Materias Primas" },
  "base_unit": { "id": 2, "name": "Kilogramo", "symbol": "kg" },
  "stock_min": 50,
  "stock_max": 200,
  "current_stock": 0,
  "created_at": "2025-10-31T12:00:00Z"
}
```

---

### 2.4 Base de Datos

#### 2.4.1 Tablas Principales
```sql
✅ items                      // Items maestros
✅ item_vendor                // Relación ítem-proveedor
✅ item_uom                   // Presentaciones (UOM conversiones)
✅ item_vendor_prices         // Precios históricos por proveedor
✅ batches                    // Lotes físicos con caducidad
✅ inventory_transactions     // Kardex (movimientos)
✅ inventory_counts           // Conteos físicos (header)
✅ inventory_count_lines      // Líneas de conteo (detail)
✅ warehouses                 // Almacenes/sucursales
✅ units                      // Unidades de medida (UOM)
✅ categories                 // Categorías de ítems
```

#### 2.4.2 Funciones y Vistas PostgreSQL
```sql
✅ fn_item_unit_cost_at(item_id, fecha)          // Costo unitario a fecha específica
✅ vw_item_last_price                             // Último precio por ítem
✅ vw_item_last_price_pref                        // Precio del proveedor preferente
✅ vw_inventory_stock_summary                     // Resumen de stock por almacén
✅ fn_calculate_stock_by_fefo(item_id, wh_id)    // Stock disponible FEFO
```

#### 2.4.3 Índices Optimizados
```sql
✅ items: idx_items_code, idx_items_category, idx_items_active
✅ batches: idx_batches_expiry_date, idx_batches_item_warehouse
✅ inventory_transactions: idx_invtrans_item_date, idx_invtrans_type
✅ item_vendor_prices: idx_itemvendor_prices_date
```

#### 2.4.4 Normalización Completada
- ✅ **Phase 2.1**: Normalización de `items`, eliminación de duplicados
- ✅ **Phase 2.2**: Relaciones `item_vendor`, `item_uom`
- ✅ **Phase 2.3**: Tabla de precios históricos `item_vendor_prices`
- ✅ **Phase 2.4**: Optimización de índices y constraints

---

### 2.5 Permisos Implementados

| Permiso | Descripción | Asignado a |
|---------|-------------|------------|
| `inventory.items.view` | Ver catálogo de ítems | Todos |
| `inventory.items.manage` | Crear/Editar ítems | Gerente, Admin |
| `inventory.uoms.view` | Ver presentaciones | Todos |
| `inventory.uoms.manage` | Gestionar conversiones UOM | Gerente |
| `inventory.receptions.view` | Ver recepciones | Almacén, Gerente |
| `inventory.receptions.post` | Postear recepciones a inventario | Almacén, Gerente |
| `inventory.counts.view` | Ver conteos físicos | Todos |
| `inventory.counts.open` | Iniciar conteo | Almacén, Gerente |
| `inventory.counts.close` | Cerrar y ajustar conteo | Gerente, Admin |
| `inventory.moves.view` | Ver movimientos | Todos |
| `inventory.moves.adjust` | Ajuste manual de inventario | Gerente, Admin |
| `inventory.snapshot.generate` | Generar snapshot diario | Sistema, Admin |
| `inventory.snapshot.view` | Ver snapshots históricos | Gerente, Admin |

---

## 3. FUNCIONALIDADES IMPLEMENTADAS

### 3.1 Items / Altas
- ✅ Filtro claro de búsqueda (por nombre, código, categoría)
- ✅ Generación automática de código `CAT-SUB-#####`
- ✅ Validación básica con mensajes genéricos
- ✅ Asociación de UOM base
- ✅ Catálogo de presentaciones por proveedor
- ✅ Soft delete con auditoría
- ⚠️ Validación inline con mensajes específicos (pendiente mejorar)
- ❌ Wizard de alta en 2 pasos (pendiente)
- ❌ Sugerencias de nombres normalizados (pendiente)

### 3.2 Recepciones
- ✅ Modal "Nueva recepción" con Proveedor/Sucursal/Almacén
- ✅ Líneas con: Producto, Qty, UOM compra, Pack size, Lote, Caducidad, Temperatura
- ✅ Campos para evidencia fotográfica
- ✅ Estructura FEFO (First Expire First Out)
- ✅ Snapshot de precios al postear
- ✅ Estados: Pre-validada → Aprobada → Posteada
- ⚠️ Auto-lookup por código proveedor (básico, mejorar)
- ⚠️ Conversión automática presentación→base (implementado, falta tooltip)
- ❌ Adjuntos múltiples con drag-and-drop (pendiente)
- ❌ OCR para leer lote/caducidad desde foto (pendiente)
- ❌ Plantillas de recepción frecuentes (pendiente)
- ❌ Tolerancias de cantidad automáticas (pendiente)

### 3.3 Lotes / Caducidades / Conteos
- ✅ Rejillas con filtros por almacén, categoría, estado
- ✅ Sistema de conteos con workflow completo (4 estados)
- ✅ Tablero de lotes por caducidad
- ✅ Alertas visuales (OK, Bajo stock, Por caducar)
- ✅ Cálculo automático de variaciones sistema vs físico
- ✅ Generación automática de ajustes en kardex
- ✅ Estadísticas de exactitud por conteo
- ⚠️ Vistas de tarjeta con chips de estado (básico, mejorar diseño)
- ❌ Acciones masivas: "Imprimir etiquetas" (pendiente)
- ❌ Mobile-first para conteo rápido (pendiente)
- ❌ Escaneo de código de barras (pendiente)

### 3.4 Transferencias
- ✅ Listado con estados (Borrador/Despachada/Recibida)
- ✅ Creación con origen/destino
- ✅ Líneas con UOM y conversión automática
- ⚠️ Flujo 3 pasos implementado (mejorar UX de confirmaciones)
- ⚠️ Confirmaciones parciales (funcional, mejorar UI)
- ❌ UI de "reconciliación" entre enviado/recibido (pendiente)
- ❌ Discrepancias con workflow de aprobación (pendiente)

### 3.5 Costos e Inventario
- ✅ Función `fn_item_unit_cost_at` para costos históricos
- ✅ Vista `vw_item_last_price` para precios vigentes
- ✅ Vista `vw_item_last_price_pref` para proveedor preferente
- ✅ API `POST /api/inventory/prices` para registrar precios
- ✅ API `GET /api/recipes/{id}/cost?at=YYYY-MM-DD` para costos de recetas
- ⚠️ Interfaz de captura de precios desde UI (básica, mejorar)
- ❌ Validación automática contra catálogo UOM (pendiente)
- ❌ Vista de alertas de costo pendientes (pendiente)
- ❌ Simulador de impacto de cambios de costo (pendiente)

---

## 4. GAPS IDENTIFICADOS

### 4.1 Críticos (🔴 Bloqueantes para MVP)
1. ❌ **Wizard de alta de ítems en 2 pasos**
   - **Impacto**: UX muy compleja en un solo formulario
   - **Esfuerzo**: M (1-2 días)
   - **Dependencias**: Ninguna

2. ❌ **Validación inline mejorada**
   - **Impacto**: Usuarios frustrados con mensajes genéricos
   - **Esfuerzo**: S (2-4 horas)
   - **Dependencias**: Refactorizar validaciones backend

3. ❌ **Mobile UI para conteos físicos**
   - **Impacto**: Operadores usan tablets en almacén
   - **Esfuerzo**: L (3-5 días)
   - **Dependencias**: Diseño responsive + Alpine.js

### 4.2 Altos (🟡 Importantes para calidad)
4. ⚠️ **Conversión UOM con tooltips explicativos**
   - **Impacto**: Confusión en conversiones de presentación
   - **Esfuerzo**: XS (<2 horas)
   - **Dependencias**: Solo frontend

5. ❌ **Adjuntos múltiples con drag-and-drop**
   - **Impacto**: Experiencia de usuario mejorada
   - **Esfuerzo**: M (1-2 días)
   - **Dependencias**: Librería JS (Dropzone.js)

6. ❌ **Plantillas de recepción frecuentes**
   - **Impacto**: Acelera recepciones repetitivas
   - **Esfuerzo**: M (1-2 días)
   - **Dependencias**: Nueva tabla `reception_templates`

### 4.3 Medios (🟢 Deseables)
7. ❌ **OCR para leer lote/caducidad**
   - **Impacto**: Reduce errores de captura manual
   - **Esfuerzo**: XL (1-2 semanas)
   - **Dependencias**: Integración Tesseract OCR / Google Vision API

8. ❌ **Simulador de impacto de costos**
   - **Impacto**: Previene errores costosos antes de aplicar
   - **Esfuerzo**: L (3-5 días)
   - **Dependencias**: Job de recálculo de recetas

9. ❌ **Escaneo de código de barras móvil**
   - **Impacto**: Acelera conteos y recepciones
   - **Esfuerzo**: M (1-2 días)
   - **Dependencias**: Librería QuaggaJS / HTML5 Camera API

### 4.4 Bajos (⚪ Nice-to-have)
10. ❌ **Sugerencias de nombres normalizados con IA**
    - **Impacto**: Mejora consistencia del catálogo
    - **Esfuerzo**: L (3-5 días)
    - **Dependencias**: Integración OpenAI API / GPT-3

11. ❌ **Reportes programados de inventario**
    - **Impacto**: Automatiza envío de reportes
    - **Esfuerzo**: S (2-4 horas)
    - **Dependencias**: Queue system ya disponible

---

## 5. ROADMAP DEL MÓDULO

### 5.1 Fase 3: Inventario Sólido (Semanas 5-7)
**Objetivo**: Completar gaps críticos y altos

**Sprint 1 (Semana 5)**: UX Refinement
- ✅ Wizard de alta de ítems en 2 pasos
- ✅ Validación inline mejorada
- ✅ Tooltips de conversión UOM
- ✅ Testing: Unit tests para servicios

**Sprint 2 (Semana 6)**: Mobile & Usability
- ✅ UI mobile-first para conteos
- ✅ Adjuntos múltiples con drag-and-drop
- ✅ Plantillas de recepción frecuentes
- ✅ Testing: Feature tests para workflows

**Sprint 3 (Semana 7)**: Polish & Documentation
- ✅ Refinar flujo de transferencias
- ✅ Mejorar dashboard de alertas
- ✅ Documentación de usuario (guías)
- ✅ Testing: E2E tests críticos

### 5.2 Fase 4: Motor Reposición (Semanas 8-10)
**Integración con módulo Inventario**:
- ✅ Validación de stock disponible antes de sugerir
- ✅ Considerar órdenes pendientes
- ✅ Cálculo de cobertura (días) por ítem
- ✅ Control de lead time por proveedor

### 5.3 Fase 5: Recetas Versionadas (Semanas 11-13)
**Integración con módulo Inventario**:
- ✅ Versionado automático al cambiar costos
- ✅ Simulador de impacto de costos
- ✅ Snapshot de costos por receta

### 5.4 Fase 7: Quick Wins & Polish (Semanas 17-18)
**Mejoras finales**:
- ✅ OCR para lote/caducidad (opcional)
- ✅ Escaneo de códigos de barras móvil
- ✅ Reportes programados

---

## 6. SPECS TÉCNICAS

### 6.1 Arquitectura del Módulo

#### 6.1.1 Flujo de Datos
```
1. Usuario crea ítem → ItemController@store
2. Validación → ItemService@validateItem()
3. Generación de código → ItemService@generateCode()
4. Guardado → Item::create() + audit log
5. Notificación → Event ItemCreated dispatched
```

#### 6.1.2 Patrón de Diseño: Service Layer
```php
// Ejemplo: InventoryCountService
class InventoryCountService {
    public function createCount($data) {
        DB::transaction(function() use ($data) {
            // 1. Crear header
            $count = InventoryCount::create([...]);
            
            // 2. Crear líneas
            foreach ($data['lines'] as $line) {
                InventoryCountLine::create([...]);
            }
            
            // 3. Auditoría
            AuditLog::log('inventory_count_created', $count->id);
            
            // 4. Evento
            event(new InventoryCountCreated($count));
        });
    }
}
```

#### 6.1.3 Diagrama de Estados: Conteo Físico
```
BORRADOR (draft)
   ↓ [startCount()]
EN_PROCESO (in_progress)
   ↓ [captureLines()]
REVISIÓN (review)
   ↓ [finalizeCount()]
AJUSTADO (adjusted) + Movimientos en Kardex
```

### 6.2 Reglas de Negocio

#### 6.2.1 Generación de Código de Ítem
```php
// Formato: CAT-SUB-#####
// Ejemplo: CAT05-SUB02-00123

// Reglas:
- CAT: ID de categoría (2 dígitos, zero-padded)
- SUB: ID de subcategoría (2 dígitos, zero-padded)
- #####: Secuencial por subcategoría (5 dígitos, zero-padded)
```

#### 6.2.2 FEFO (First Expire First Out)
```sql
-- Al consumir inventario, se toma del lote más próximo a caducar:
SELECT * FROM batches
WHERE item_id = ? AND warehouse_id = ?
  AND expiry_date > CURRENT_DATE
  AND quantity_remaining > 0
ORDER BY expiry_date ASC
LIMIT 1;
```

#### 6.2.3 Cálculo de Costo Unitario
```sql
-- Función: fn_item_unit_cost_at(item_id, fecha)
-- Lógica: Promedio ponderado de recepciones hasta fecha
SELECT SUM(qty * unit_cost) / SUM(qty)
FROM item_vendor_prices
WHERE item_id = $1 AND date <= $2;
```

#### 6.2.4 Conversión de Presentaciones
```php
// Ejemplo: "Caja 12 unidades" → Unidades base
$baseQty = $presentationQty * $packSize;

// Pack size almacenado en item_uom:
// item_uom.factor = 12 (1 caja = 12 unidades)
```

### 6.3 Validaciones

#### 6.3.1 Alta de Ítems
```php
[
    'name' => 'required|string|max:255|unique:items,name',
    'category_id' => 'required|exists:categories,id',
    'base_unit_id' => 'required|exists:units,id',
    'stock_min' => 'nullable|numeric|min:0',
    'stock_max' => 'nullable|numeric|gte:stock_min',
]
```

#### 6.3.2 Recepción de Mercancía
```php
[
    'vendor_id' => 'required|exists:vendors,id',
    'warehouse_id' => 'required|exists:warehouses,id',
    'lines' => 'required|array|min:1',
    'lines.*.item_id' => 'required|exists:items,id',
    'lines.*.quantity' => 'required|numeric|min:0.01',
    'lines.*.unit_cost' => 'required|numeric|min:0',
    'lines.*.batch_number' => 'required|string|max:50',
    'lines.*.expiry_date' => 'required|date|after:today',
]
```

#### 6.3.3 Conteo Físico
```php
[
    'warehouse_id' => 'required|exists:warehouses,id',
    'count_date' => 'required|date|before_or_equal:today',
    'lines' => 'required|array|min:1',
    'lines.*.item_id' => 'required|exists:items,id',
    'lines.*.quantity_counted' => 'required|numeric|min:0',
]
```

### 6.4 Jobs y Commands

#### 6.4.1 Artisan Commands
```bash
# Generar snapshot diario de inventario
php artisan inventory:snapshot --date=2025-10-31

# Calcular stock teórico vs físico
php artisan inventory:reconcile --warehouse=1

# Alertas de caducidad próxima (7 días)
php artisan inventory:check-expiry --days=7

# Recalcular costos por cambio de precio
php artisan inventory:recalculate-costs --item=123
```

#### 6.4.2 Jobs en Queue
```php
// Procesamiento de recepciones
ProcessReceptionJob::dispatch($reception);

// Generación de ajustes de conteo
GenerateCountAdjustmentsJob::dispatch($count);

// Recálculo de costos de recetas
RecalculateRecipeCostsJob::dispatch($item);

// OCR de adjuntos (futuro)
ProcessReceiptOCRJob::dispatch($attachment);
```

### 6.5 Eventos y Listeners

#### 6.5.1 Eventos
```php
ItemCreated        // Disparado al crear ítem
ItemUpdated        // Disparado al actualizar ítem
ReceptionPosted    // Disparado al postear recepción
CountFinalized     // Disparado al finalizar conteo
StockLowAlert      // Disparado cuando stock < stock_min
ExpiryAlert        // Disparado cuando caducidad < 7 días
```

#### 6.5.2 Listeners
```php
SendStockLowNotification        // Email a gerente
UpdateRecipeCosts               // Recalcular recetas afectadas
LogInventoryAudit               // Registro en audit_log
GenerateInventorySnapshot       // Snapshot automático
```

---

## 7. TESTING

### 7.1 Coverage Actual
- **Unit Tests**: 25% (servicios principales)
- **Feature Tests**: 30% (workflows críticos)
- **Integration Tests**: 20% (API endpoints)
- **E2E Tests**: 10% (flujos completos)

**Total Coverage**: ~30% 🔴

### 7.2 Tests Implementados

#### 7.2.1 Unit Tests
```php
✅ ItemServiceTest::test_can_create_item()
✅ ItemServiceTest::test_generates_unique_code()
✅ InventoryCountServiceTest::test_calculates_variances()
✅ ReceivingServiceTest::test_posts_to_inventory()
⚠️ CostingServiceTest (básico, ampliar)
```

#### 7.2.2 Feature Tests
```php
✅ ItemManagementTest::test_user_can_create_item()
✅ ReceptionWorkflowTest::test_full_reception_workflow()
✅ InventoryCountTest::test_count_adjustment_creates_movements()
❌ TransferWorkflowTest (pendiente)
❌ BatchExpiryTest (pendiente)
```

#### 7.2.3 API Tests
```php
✅ ItemApiTest::test_list_items()
✅ ItemApiTest::test_create_item()
✅ StockApiTest::test_get_stock_by_item()
⚠️ MovementApiTest (parcial)
❌ CountApiTest (pendiente)
```

### 7.3 Tests Faltantes (Críticos)

1. **TransferWorkflowTest** - Flujo completo de transferencias
2. **BatchExpiryTest** - Lógica FEFO y alertas
3. **CostCalculationTest** - Validar `fn_item_unit_cost_at`
4. **PermissionsTest** - Validar control de acceso por rol
5. **ValidationTest** - Validaciones inline y errores específicos

### 7.4 Estrategia de Testing

#### 7.4.1 Prioridad 1 (Implementar en Fase 3)
- ✅ Unit tests para todos los servicios nuevos
- ✅ Feature tests para workflows críticos (recepciones, conteos)
- ✅ Validar reglas de negocio (FEFO, generación de código)

#### 7.4.2 Prioridad 2 (Implementar en Fase 7)
- ✅ E2E tests con Laravel Dusk para flujos completos
- ✅ Performance tests para queries pesadas
- ✅ Integration tests para eventos y listeners

#### 7.4.3 Cobertura Meta
- **Unit Tests**: 80%
- **Feature Tests**: 70%
- **Integration Tests**: 60%
- **E2E Tests**: 50%

**Target Total**: ~70% para producción

---

## 8. INTEGRACIONES

### 8.1 Módulo de Compras
**Dependencias**:
- Recepciones vinculadas a Purchase Orders
- Stock disponible para generar sugerencias de reposición
- Precios de proveedores para cálculo de costos

**Endpoints compartidos**:
- `POST /api/purchasing/receptions/create-from-po/{po_id}`
- `GET /api/inventory/stock/list` (usado por motor de reposición)

### 8.2 Módulo de Recetas
**Dependencias**:
- Ítems como ingredientes de recetas
- Costos unitarios para calcular costo de receta
- Versionado automático al cambiar costos

**Endpoints compartidos**:
- `GET /api/recipes/{id}/cost?at=YYYY-MM-DD`
- `GET /api/inventory/items/{id}/cost-history`

### 8.3 Módulo de Producción
**Dependencias**:
- Consumo de materias primas (descuenta inventario)
- Producción de terminados (incrementa inventario)
- Trazabilidad de lotes

**Eventos compartidos**:
- `ProductionCompleted` → descuenta ingredientes
- `ProductionPosted` → incrementa producto terminado

### 8.4 Módulo POS (FloreantPOS)
**Dependencias**:
- Consumo automático al vender (triggers DB)
- Implossión de recetas para descuento de ingredientes
- Vista en tiempo real de stock disponible

**Integración**:
- **Trigger**: `trg_pos_consumption` (ejecuta al insertar en `pos_sales`)
- **Vista**: `vw_pos_realtime_stock` (stock disponible por sucursal)

### 8.5 Módulo de Reportes
**Dependencias**:
- KPIs de inventario (rotación, valor, exactitud)
- Datos históricos de snapshots
- Alertas de stock bajo y caducidad

**Endpoints compartidos**:
- `GET /api/reports/inventory/valuation`
- `GET /api/reports/inventory/turnover`
- `GET /api/reports/inventory/accuracy`

---

## 9. KPIs MONITOREADOS

### 9.1 KPIs Operativos
| KPI | Fórmula | Meta | Frecuencia |
|-----|---------|------|------------|
| **Stock Disponible** | `SUM(batches.quantity_remaining)` | N/A | Tiempo real |
| **Valor de Inventario** | `SUM(stock * unit_cost)` | N/A | Diario |
| **Rotación de Inventario** | `COGS / Avg Inventory Value` | > 12 veces/año | Mensual |
| **Exactitud de Inventario** | `(1 - ABS(físico - sistema) / sistema) * 100` | > 95% | Por conteo |
| **Artículos por Caducar (7 días)** | `COUNT(batches WHERE expiry < NOW() + 7)` | < 5% del total | Diario |

### 9.2 KPIs Financieros
| KPI | Fórmula | Meta | Frecuencia |
|-----|---------|------|------------|
| **Costo Teórico vs Real** | `(Costo Teórico - Costo Real) / Costo Teórico * 100` | < 3% variación | Semanal |
| **Margen de Contribución** | `(Precio Venta - Costo) / Precio Venta * 100` | > 60% | Mensual |
| **Variación de Costos** | `(Costo Actual - Costo Anterior) / Costo Anterior * 100` | Track | Al cambiar |

### 9.3 KPIs de Calidad
| KPI | Fórmula | Meta | Frecuencia |
|-----|---------|------|------------|
| **Tiempo de Reposición** | `AVG(Lead Time por proveedor)` | < 3 días | Mensual |
| **Tasa de Agotados** | `COUNT(stock = 0) / COUNT(items) * 100` | < 2% | Diario |
| **Precisión de Recepciones** | `(Recepciones OK / Total Recepciones) * 100` | > 98% | Semanal |

---

## 10. REFERENCIAS

### 10.1 Links a Código
- **Modelos**: `app/Models/Item.php`, `app/Models/InventoryCount.php`
- **Servicios**: `app/Services/Inventory/*.php`
- **Controladores**: `app/Http/Controllers/ItemController.php`
- **Componentes Livewire**: `app/Http/Livewire/Inventory/*.php`
- **Vistas**: `resources/views/livewire/inventory/*.blade.php`
- **Migraciones**: `database/migrations/*_create_items_table.php`
- **Seeders**: `database/seeders/ItemSeeder.php`

### 10.2 Documentación Externa
- **Laravel 11 Eloquent**: https://laravel.com/docs/11.x/eloquent
- **Livewire 3**: https://livewire.laravel.com/docs
- **PostgreSQL Functions**: https://www.postgresql.org/docs/9.5/functions.html
- **FEFO Best Practices**: https://www.unleashedsoftware.com/blog/fefo-inventory

### 10.3 Documentación Interna
- **Plan Maestro**: `docs/UI-UX/MASTER/04_ROADMAP/00_PLAN_MAESTRO.md`
- **Design System**: `docs/UI-UX/MASTER/03_ARQUITECTURA/02_DESIGN_SYSTEM.md`
- **Database Schema**: `docs/UI-UX/MASTER/03_ARQUITECTURA/04_DATABASE_SCHEMA.md`
- **API Contracts**: `docs/UI-UX/MASTER/03_ARQUITECTURA/03_API_CONTRACTS.md`

### 10.4 Issues Relacionados
- **GitHub Issues**: (Agregar links cuando se creen)
  - #XXX: Implementar wizard de alta de ítems
  - #XXX: Mobile UI para conteos físicos
  - #XXX: OCR para lote/caducidad

---

## 11. CHANGELOG

### 2025-10-31
- ✨ Creación de documentación completa del módulo Inventario
- ✨ Consolidación de `Definiciones/Inventario.md` + `Status/STATUS_Inventario.md`
- ✨ Análisis de gaps críticos y roadmap
- ✨ Specs técnicas detalladas con ejemplos de código
- ✨ Estrategia de testing y cobertura

---

## 12. PRÓXIMOS PASOS INMEDIATOS

### Esta Semana (Prioridad 🔴)
1. ✅ **Validar documentación con Tech Lead**
2. ⏳ **Crear issues en GitHub** para gaps críticos
3. ⏳ **Asignar tareas** a desarrolladores/IAs
4. ⏳ **Iniciar Sprint 1 de Fase 3**: Wizard de alta + validación inline

### Próximas 2 Semanas
- Completar Sprint 1 y Sprint 2 de Fase 3
- Aumentar cobertura de tests a 50%
- Refinar UX de recepciones y conteos

---

**Mantenido por**: Equipo TerrenaLaravel  
**Próxima review**: Después de completar Fase 3  
**Feedback**: Enviar a tech-lead@terrena.com

---

**🎉 Documentación completada - Inventario Module v1.0**
