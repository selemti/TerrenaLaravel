# SISTEMA DE CONTEOS DE INVENTARIO

## 📋 Índice

1. [Resumen](#resumen)
2. [Arquitectura](#arquitectura)
3. [Modelos](#modelos)
4. [Componentes Livewire](#componentes-livewire)
5. [Vistas](#vistas)
6. [Flujos de Trabajo](#flujos-de-trabajo)
7. [Rutas](#rutas)
8. [Instalación](#instalación)

---

## Resumen

Sistema completo para gestionar conteos físicos de inventario con ajustes automáticos.

### Características

- ✅ Creación de conteos programados
- ✅ Captura de conteos físicos por item
- ✅ Cálculo automático de variaciones
- ✅ Generación automática de ajustes en kardex
- ✅ Estadísticas y reportes de exactitud
- ✅ Filtros y búsquedas
- ✅ Integración con sistema de inventario existente

### Tecnologías

- **Backend:** Laravel 12, Livewire 3.7, PostgreSQL
- **Frontend:** Bootstrap 5, Alpine.js, Font Awesome 6
- **Service Layer:** `InventoryCountService` (existente de Codex)

---

## Arquitectura

### Estados del Flujo

```
BORRADOR → EN_PROCESO → AJUSTADO
                    ↓
                CANCELADO
```

**Estados:**
- `BORRADOR`: Conteo creado pero no iniciado
- `EN_PROCESO`: Conteo abierto, captura en progreso
- `AJUSTADO`: Conteo finalizado, ajustes aplicados
- `CANCELADO`: Conteo cancelado

### Estructura de Datos

**Tablas:**
1. `inventory_counts` - Encabezados de conteos
2. `inventory_count_lines` - Líneas de conteo (items individuales)
3. `mov_inv` - Movimientos de ajuste (generados automáticamente)

---

## Modelos

### InventoryCount

**Archivo:** `app/Models/InventoryCount.php`

**Propiedades principales:**
- `folio` - Identificador único (generado automáticamente)
- `sucursal_id` - Sucursal donde se realiza
- `almacen_id` - Almacén específico
- `estado` - Estado actual del conteo
- `total_items` - Total de items en conteo
- `total_variacion` - Total de variación calculada
- `programado_para` - Fecha programada
- `iniciado_en` - Fecha/hora de inicio
- `cerrado_en` - Fecha/hora de cierre

**Relaciones:**
```php
$count->lines;           // Líneas del conteo
$count->createdBy;       // Usuario creador
$count->closedBy;        // Usuario que cerró
```

**Accessors útiles:**
```php
$count->total_con_variacion;     // Count de items con variación
$count->porcentaje_exactitud;    // % de items exactos
$count->estado_badge;            // Badge HTML del estado
```

**Scopes:**
```php
InventoryCount::enProceso()->get();        // Solo en proceso
InventoryCount::ajustados()->get();        // Solo ajustados
InventoryCount::porSucursal($id)->get();   // Por sucursal
```

---

### InventoryCountLine

**Archivo:** `app/Models/InventoryCountLine.php`

**Propiedades principales:**
- `item_id` - Item a contar
- `inventory_batch_id` - Lote específico (opcional)
- `qty_teorica` - Cantidad en sistema
- `qty_contada` - Cantidad física contada
- `qty_variacion` - Diferencia calculada
- `uom` - Unidad de medida
- `motivo` - Razón de la variación

**Relaciones:**
```php
$line->inventoryCount;   // Conteo principal
$line->item;             // Item
$line->batch;            // Lote (si aplica)
```

**Accessors útiles:**
```php
$line->variacion_absoluta;       // Abs(variación)
$line->porcentaje_variacion;     // % de variación
$line->tipo_variacion;           // EXACTO|SOBRANTE|FALTANTE
$line->variacion_badge;          // Badge HTML
```

---

## Componentes Livewire

### 1. Index - Listado de Conteos

**Archivo:** `app/Livewire/InventoryCount/Index.php`
**Vista:** `resources/views/livewire/inventory-count/index.blade.php`
**Ruta:** `/inventory/counts`

**Funcionalidad:**
- Listado paginado de conteos
- Filtros: búsqueda, estado, sucursal, almacén
- Acciones rápidas según estado

**Propiedades:**
```php
public string $search = '';
public string $estadoFilter = 'all';
public string $sucursalFilter = 'all';
public string $almacenFilter = 'all';
```

---

### 2. Create - Nuevo Conteo

**Archivo:** `app/Livewire/InventoryCount/Create.php`
**Vista:** `resources/views/livewire/inventory-count/create.blade.php`
**Ruta:** `/inventory/counts/create`

**Funcionalidad:**
- Selección de items a contar
- Configuración de sucursal/almacén
- Carga automática de stock teórico
- Creación del conteo

**Métodos principales:**
```php
toggleItem($itemId)      // Seleccionar/deseleccionar item
seleccionarTodos()       // Seleccionar todos los items
limpiarSeleccion()       // Limpiar selección
crearConteo()            // Crear y abrir conteo
```

---

### 3. Capture - Captura Física

**Archivo:** `app/Livewire/InventoryCount/Capture.php`
**Vista:** `resources/views/livewire/inventory-count/capture.blade.php`
**Ruta:** `/inventory/counts/{id}/capture`

**Funcionalidad:**
- Captura de cantidades físicas
- Cálculo en tiempo real de variaciones
- Barra de progreso
- Filtros para facilitar captura

**Métodos principales:**
```php
actualizarConteo($lineId, $cantidad)  // Actualizar qty contada
guardarYContinuar()                   // Guardar progreso
finalizarCaptura()                    // Ir a revisión
```

---

### 4. Review - Revisión y Ajuste

**Archivo:** `app/Livewire/InventoryCount/Review.php`
**Vista:** `resources/views/livewire/inventory-count/review.blade.php`
**Ruta:** `/inventory/counts/{id}/review`

**Funcionalidad:**
- Revisión de variaciones calculadas
- Estadísticas de exactitud
- Filtros por tipo de variación
- Confirmación para generar ajustes

**Métodos principales:**
```php
openConfirmModal()   // Abrir confirmación
finalizarConteo()    // Generar ajustes y cerrar
volver()             // Regresar a captura
```

**⚠️ IMPORTANTE:** Al finalizar, se generan movimientos tipo `AJUSTE` en `mov_inv` automáticamente.

---

### 5. Detail - Detalle de Conteo Finalizado

**Archivo:** `app/Livewire/InventoryCount/Detail.php`
**Vista:** `resources/views/livewire/inventory-count/detail.blade.php`
**Ruta:** `/inventory/counts/{id}/detail`

**Funcionalidad:**
- Vista de solo lectura de conteo finalizado
- Estadísticas completas
- Valor monetario de variaciones
- Exportación (PDF/Excel - futuro)

---

## Vistas

Todas las vistas usan **Bootstrap 5** con diseño responsivo.

### Elementos Comunes

**Badges de Estado:**
- `BORRADOR`: gris
- `EN_PROCESO`: azul
- `AJUSTADO`: verde
- `CANCELADO`: rojo

**Badges de Variación:**
- `EXACTO`: verde
- `SOBRANTE`: info (+cantidad)
- `FALTANTE`: warning (-cantidad)

### Componentes Reutilizables

**Cards de Estadísticas:**
```html
<div class="card shadow-sm text-center border-success">
    <div class="card-body">
        <h3 class="mb-0 text-success">25</h3>
        <small class="text-muted">Exactos</small>
    </div>
</div>
```

**Filtros por Tipo:**
```html
<div class="btn-group" role="group">
    <input type="radio" wire:model.live="filterVariacion" value="all">
    <label>Todos</label>
    <!-- ... -->
</div>
```

---

## Flujos de Trabajo

### Flujo 1: Conteo Completo Normal

```
1. Usuario → Create → Selecciona items → Crea Conteo
   ↓
2. Sistema → Genera folio → Carga qty_teorica del kardex → Estado: EN_PROCESO
   ↓
3. Usuario → Capture → Cuenta físicamente → Captura qty_contada
   ↓
4. Sistema → Calcula variaciones en tiempo real
   ↓
5. Usuario → Review → Revisa variaciones → Confirma
   ↓
6. Sistema → Genera ajustes en mov_inv → Estado: AJUSTADO
```

### Flujo 2: Corrección Durante Captura

```
1. Usuario está en Capture
2. Se equivoca en una cantidad
3. Modifica el valor en el input
4. Sistema recalcula variación automáticamente
5. Click "Guardar" para persistir
6. Continúa capturando
```

### Flujo 3: Volver Atrás desde Review

```
1. Usuario en Review
2. Detecta error en captura
3. Click "Volver a Captura"
4. Sistema regresa a Capture
5. Usuario corrige
6. Regresa a Review
7. Finaliza
```

---

## Rutas

**Archivo:** `routes/web.php`

```php
// Prefijo: /inventory/counts
Route::get('/counts',              Index::class)->name('inv.counts.index');
Route::get('/counts/create',       Create::class)->name('inv.counts.create');
Route::get('/counts/{id}/capture', Capture::class)->name('inv.counts.capture');
Route::get('/counts/{id}/review',  Review::class)->name('inv.counts.review');
Route::get('/counts/{id}/detail',  Detail::class)->name('inv.counts.detail');
```

**URLs completas:**
- Index: `http://localhost/TerrenaLaravel/inventory/counts`
- Create: `http://localhost/TerrenaLaravel/inventory/counts/create`
- Capture: `http://localhost/TerrenaLaravel/inventory/counts/4/capture`
- Review: `http://localhost/TerrenaLaravel/inventory/counts/4/review`
- Detail: `http://localhost/TerrenaLaravel/inventory/counts/4/detail`

---

## Instalación

### Prerrequisitos

✅ Migración ya ejecutada: `2025_11_15_010000_create_inventory_counts_tables.php`
✅ Service ya existe: `app/Services/Inventory/InventoryCountService.php`
✅ Tablas `mov_inv`, `items`, `inventory_batches` existen

### Paso 1: Verificar Migraciones

```bash
php artisan migrate:status
```

Debe aparecer:
```
Ran    2025_11_15_010000_create_inventory_counts_tables
```

### Paso 2: Verificar Rutas

```bash
php artisan route:list | grep counts
```

Debe mostrar las 5 rutas del módulo.

### Paso 3: Verificar Menú

Ir a `/dashboard` → Menú lateral → Inventario → Debe aparecer "Conteos"

### Paso 4: Prueba Básica

1. Ir a `/inventory/counts`
2. Click "Nuevo Conteo"
3. Seleccionar 2-3 items
4. Click "Crear Conteo"
5. Capturar cantidades
6. Click "Continuar a Revisión"
7. Revisar variaciones
8. Click "Finalizar y Generar Ajustes"
9. Ver detalle final

---

## Integración con Sistema Existente

### Con InventoryCountService

El sistema usa el servicio existente de Codex:

```php
$service = new InventoryCountService();

// Abrir conteo
$countId = $service->open($header, $lines);

// Finalizar conteo
$service->finalize($countId, $lines, $userId, $notes);
```

### Con Kardex (mov_inv)

Al finalizar, se generan automáticamente movimientos tipo `AJUSTE`:

```sql
INSERT INTO mov_inv (
    item_id,
    tipo,          -- 'AJUSTE'
    qty,           -- variación (puede ser negativa)
    ref_tipo,      -- 'inventory_count'
    ref_id,        -- ID del conteo
    ...
)
```

### Con Items

Se usa la relación existente para mostrar datos del item:

```php
$line->item->codigo
$line->item->nombre
$line->item->costo_promedio  // Para calcular valor de variación
```

---

## Archivos del Sistema

### Modelos (2)
- `app/Models/InventoryCount.php`
- `app/Models/InventoryCountLine.php`

### Componentes Livewire (5)
- `app/Livewire/InventoryCount/Index.php`
- `app/Livewire/InventoryCount/Create.php`
- `app/Livewire/InventoryCount/Capture.php`
- `app/Livewire/InventoryCount/Review.php`
- `app/Livewire/InventoryCount/Detail.php`

### Vistas (5)
- `resources/views/livewire/inventory-count/index.blade.php`
- `resources/views/livewire/inventory-count/create.blade.php`
- `resources/views/livewire/inventory-count/capture.blade.php`
- `resources/views/livewire/inventory-count/review.blade.php`
- `resources/views/livewire/inventory-count/detail.blade.php`

### Configuración
- `routes/web.php` (5 rutas añadidas)
- `resources/views/layouts/terrena.blade.php` (1 enlace en menú)

### Documentación
- `docs/InventoryCounts/README.md` (este archivo)

---

## 🎉 Sistema Completado

- **2 Modelos Eloquent** con relaciones, accessors y scopes
- **5 Componentes Livewire** full-stack
- **5 Vistas Blade** con Bootstrap 5
- **Integración completa** con sistema existente
- **Flujo end-to-end** funcionando
- **Documentación completa**

**Total:** ~3,000 líneas de código

---

## Soporte

Para preguntas o issues, revisar:
1. Esta documentación
2. Comentarios en el código
3. Documentación de Caja Chica (patrón similar)

**Creado con:** Claude Code (Anthropic)
**Fecha:** Octubre 2023
**Versión:** 1.0
