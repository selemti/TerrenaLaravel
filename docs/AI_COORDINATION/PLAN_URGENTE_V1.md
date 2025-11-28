# 🔥 PLAN URGENTE - Prioridades Críticas
**Fecha**: 26 de noviembre de 2025
**Coordinador**: Claude Code
**Estado**: EJECUCIÓN INMEDIATA

---

## 🚨 PRIORIDADES DEL USUARIO

1. **🔥 CRÍTICO**: Reportes de ventas NO coinciden entre POS y diferentes reportes
2. **⚡ URGENTE**: Finalizar Inventarios completamente
3. **⚡ URGENTE**: Validar Transferencias funcionen correctamente
4. **⚡ URGENTE**: Completar Recetas + Producción para liberar sistema

**POSTERGADO**: Homologación UI (Design System) - Lo haremos después

---

## 🔍 DIAGNÓSTICO: BUG REPORTES DE VENTAS

### Fuentes de Datos Identificadas:

**Dashboard (`/dashboard`)** obtiene datos de múltiples endpoints:

1. `/api/reports/kpis/sucursal` → `selemti.vw_dashboard_resumen_sucursal` (**Vista materializada**)
2. `/api/reports/kpis/terminal` → `selemti.vw_dashboard_resumen_terminal` (**Vista materializada**)
3. `/api/reports/ventas/top` → `public.ticket_item` (tabla real POS)
4. `/api/reports/ticket/promedio` → `selemti.vw_dashboard_ticket_base` (**Vista materializada**)
5. `/api/reports/ventas/dia` → `selemti.vw_dashboard_resumen_sucursal` (**Vista materializada**)
6. `/api/reports/ventas/hora` → `selemti.vw_dashboard_ventas_hora` (**Vista materializada**)
7. `/api/reports/ventas/formas` → origen pendiente de validar

**Reportes adicionales** (`/reports/sales/*`):
- Sales Mix, Sales Drawer, Sales Diagnostics, Sales Mods, Sales Detail, Sales Summary, etc.
- Múltiples controladores en `app/Http/Controllers/Reports/Sales*.php`

### 🔴 PROBLEMA IDENTIFICADO:

**Vistas materializadas NO se están refrescando** o tienen **definiciones inconsistentes** con las tablas reales del POS.

**Síntomas**:
- Dashboard muestra cifras diferentes a reportes detallados
- Diferentes reportes muestran cifras diferentes entre sí
- No coinciden con los valores reales del POS (schema `public`)

### 🎯 CAUSA RAÍZ (hipótesis):

1. **Vistas materializadas desactualizadas**: No hay proceso automático de `REFRESH MATERIALIZED VIEW`
2. **Inconsistencia en queries**: Diferentes reportes usan diferentes lógicas para calcular ventas
3. **Filtros de fecha inconsistentes**: Algunos usan `closing_date`, otros `created_date`
4. **Tickets anulados**: Algunos reportes no filtran `voided = false` correctamente
5. **Pagos parciales**: Inconsistencia en manejo de `paid = true`

---

## 📋 FASE 0: DIAGNÓSTICO Y CORRECCIÓN REPORTES (CRÍTICO)
**Duración estimada**: 8-12 horas
**Agente principal**: QWEN
**Validador**: CLAUDE

### PROMPT PARA QWEN - PARTE 1: AUDITORÍA BD

```
TAREA URGENTE: Auditar vistas materializadas y fuentes de datos de reportes

CONTEXTO:
- Usuario reporta que cifras de ventas NO coinciden entre Dashboard y Reportes
- Hay múltiples fuentes de datos: vistas materializadas y consultas directas
- Base de datos: PostgreSQL 9.5, schemas: public (POS legacy) y selemti (trabajo)

ANÁLISIS REQUERIDO:

1. LISTAR TODAS LAS VISTAS MATERIALIZADAS:
   ```sql
   SELECT
     schemaname,
     matviewname,
     definition
   FROM pg_matviews
   WHERE schemaname IN ('public', 'selemti')
   ORDER BY schemaname, matviewname;
   ```

2. VALIDAR CADA VISTA MATERIALIZADA RELACIONADA CON VENTAS:
   - selemti.vw_dashboard_resumen_sucursal
   - selemti.vw_dashboard_resumen_terminal
   - selemti.vw_dashboard_ticket_base
   - selemti.vw_dashboard_ventas_hora
   - selemti.vw_dashboard_ventas_categorias

   Para cada una:
   a) Obtener definición completa
   b) Validar última actualización:
      SELECT schemaname, matviewname, last_refresh
      FROM pg_stat_user_tables
      WHERE relname LIKE 'vw_dashboard%';

   c) Identificar tablas origen (public vs selemti)
   d) Validar lógica de filtrado (voided, paid, closing_date)

3. COMPARAR TOTALES ENTRE FUENTES:
   Ejecutar para HOY:

   a) Total desde vista materializada:
   ```sql
   SELECT SUM(venta_total) AS total_vista
   FROM selemti.vw_dashboard_resumen_sucursal
   WHERE fecha = CURRENT_DATE;
   ```

   b) Total desde tabla real POS:
   ```sql
   SELECT SUM(t.total) AS total_real
   FROM public.ticket t
   WHERE DATE(t.closing_date) = CURRENT_DATE
     AND t.paid = true
     AND t.voided = false;
   ```

   c) ¿Coinciden? Si NO → documentar diferencia

4. IDENTIFICAR PROCESO DE REFRESH:
   - ¿Existe un cron job que refresque las vistas?
   - ¿Hay triggers que las actualicen?
   - ¿Se refrescan manualmente?

5. REVISAR OTRAS FUENTES DE DATOS:
   - ¿Qué tablas/vistas usa cada endpoint de /api/reports/*?
   - ¿Son consistentes entre sí?

ENTREGABLE:
- docs/AUDIT/REPORTES_VENTAS_DIAGNOSTICO.md con:
  - Lista completa de vistas materializadas
  - Última actualización de cada vista
  - Comparativa de totales (vista vs tabla real)
  - Identificación de inconsistencias específicas
  - Recomendaciones de corrección
  - Script SQL para refrescar todas las vistas

FORMATO:
## Vista: selemti.vw_dashboard_resumen_sucursal
- **Última actualización**: 2025-11-20 08:00:00
- **Definición**: [SQL completo]
- **Tablas origen**: public.ticket, public.ticket_item
- **Filtros aplicados**: paid = true, voided = false
- **Inconsistencia detectada**: ✅ Ninguna | ❌ [descripción]
- **Total hoy (vista)**: $12,345.67
- **Total hoy (tabla real)**: $12,890.00
- **Diferencia**: $544.33 (4.4%)

## Recomendaciones:
1. Refrescar vistas con comando: [SQL]
2. Implementar cron job diario: [script]
3. Corregir definición de vista X: [SQL]
```

---

### PROMPT PARA QWEN - PARTE 2: CORRECCIÓN

```
TAREA: Corregir inconsistencias en reportes de ventas

BASADO EN EL DIAGNÓSTICO ANTERIOR:

1. REFRESCAR TODAS LAS VISTAS MATERIALIZADAS:
   ```sql
   REFRESH MATERIALIZED VIEW selemti.vw_dashboard_resumen_sucursal;
   REFRESH MATERIALIZED VIEW selemti.vw_dashboard_resumen_terminal;
   REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ticket_base;
   REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ventas_hora;
   REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ventas_categorias;
   ```

2. CORREGIR DEFINICIONES INCONSISTENTES:
   - Si encuentras filtros diferentes entre vistas
   - Unificar criterios: paid = true, voided = false
   - Usar closing_date (no created_date) para todas

3. CREAR FUNCIÓN DE REFRESH AUTOMÁTICO:
   ```sql
   CREATE OR REPLACE FUNCTION selemti.refresh_dashboard_views()
   RETURNS void AS $$
   BEGIN
     REFRESH MATERIALIZED VIEW selemti.vw_dashboard_resumen_sucursal;
     REFRESH MATERIALIZED VIEW selemti.vw_dashboard_resumen_terminal;
     REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ticket_base;
     REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ventas_hora;
     REFRESH MATERIALIZED VIEW selemti.vw_dashboard_ventas_categorias;
     RAISE NOTICE 'Dashboard views refreshed at %', NOW();
   END;
   $$ LANGUAGE plpgsql;
   ```

4. VALIDAR POST-CORRECCIÓN:
   - Volver a comparar totales
   - Confirmar que ahora coinciden
   - Documentar diferencias restantes (si las hay)

ENTREGABLE:
- Script SQL ejecutado
- Confirmación de refresh exitoso
- Comparativa antes/después
- Función de refresh automático creada
```

---

## 📋 FASE 1: FINALIZAR INVENTARIOS + TRANSFERENCIAS
**Duración estimada**: 5-8 horas
**Agente principal**: QWEN (validación) + CODEX (correcciones)
**Validador**: CLAUDE

### PROMPT PARA QWEN: VALIDAR INVENTARIOS

```
TAREA: Validar completitud y corrección del módulo de Inventarios

VALIDACIONES REQUERIDAS:

1. MODELOS ELOQUENT:
   - app/Models/Inv/Item.php ✓ (ya corregido)
   - app/Models/Inv/Batch.php ✓ (ya corregido)
   - app/Models/Inv/Movimiento.php ✓ (ya corregido)
   - Validar relaciones: item(), batch(), almacen(), sucursal()
   - Validar casts de campos numéricos

2. SERVICIOS:
   - app/Services/Inventory/ReceptionService.php ✓ (validado anteriormente)
   - app/Services/Inventory/TransferService.php ✓ (validado anteriormente)
   - app/Services/Inventory/InventoryCountService.php (creado por Codex)
   - Validar que todos usan DB::transaction()
   - Validar manejo de errores

3. BASE DE DATOS:
   - Validar integridad referencial:
     * mov_inv → items (item_id FK)
     * mov_inv → inventory_batch (lote_id FK)
     * mov_inv → cat_almacenes (almacen_id FK)
     * recepcion_cab → cat_proveedores (proveedor_id FK)
     * traspaso_cab → cat_almacenes (almacen_origen_id, almacen_destino_id FK)

   - Validar índices:
     * mov_inv: (item_id, ts), (ref_tipo, ref_id), (almacen_id)
     * recepcion_cab: (estado, fecha_recepcion)
     * traspaso_cab: (estado, fecha_solicitada)

4. FLUJOS CRÍTICOS - PROBAR:
   a) Recepción completa:
      - Crear recepción BORRADOR
      - Validar recepción
      - Postear recepción
      - Verificar que se creó registro en mov_inv
      - Verificar que se creó/actualizó inventory_batch

   b) Transferencia completa:
      - Crear transferencia
      - Aprobar transferencia
      - Despachar transferencia (salida de almacén origen)
      - Recibir transferencia (entrada a almacén destino)
      - Postear transferencia
      - Verificar que hay 2 movimientos en mov_inv (salida + entrada)

   c) Conteo físico:
      - Crear conteo
      - Capturar cantidades
      - Revisar varianzas
      - Postear ajuste
      - Verificar movimientos de ajuste en mov_inv

ENTREGABLE:
- docs/VALIDATION/INVENTARIOS_VALIDACION_FINAL.md con:
  - ✅ o ❌ para cada validación
  - Bugs encontrados (si los hay)
  - Flujos probados con resultados
  - Recomendaciones de corrección (si aplica)
  - Confirmación de que está listo para producción
```

---

### PROMPT PARA CODEX: CORREGIR ISSUES DE INVENTARIOS

```
TAREA: Corregir cualquier issue encontrado por QWEN en validación de Inventarios

ESPERAR REPORTE DE QWEN:
docs/VALIDATION/INVENTARIOS_VALIDACION_FINAL.md

CORREGIR:
- Modelos: Agregar relaciones o casts faltantes
- Servicios: Corregir lógica de transacciones o validaciones
- Tests: Crear pruebas unitarias para flujos críticos (opcional)

VALIDAR FUNCIONAMIENTO:
- Ejecutar flujos completos en entorno de desarrollo
- Confirmar que no hay errores en logs
- Confirmar que movimientos se registran correctamente en mov_inv

ENTREGABLE:
- Archivos corregidos
- Confirmación de pruebas exitosas
```

---

## 📋 FASE 2: COMPLETAR PRODUCCIÓN (BACKEND + UI)
**Duración estimada**: 20-25 horas
**Agente principal**: CODEX
**Validador**: QWEN (BD) + CLAUDE (lógica)

### PROMPT PARA CODEX - PARTE 1: BACKEND PRODUCCIÓN

```
TAREA: Crear backend completo para módulo de Producción

CONTEXTO:
- Modelos existentes: Receta, RecetaDetalle, RecetaVersion (en app/Models/Rec/)
- Base de datos: PostgreSQL schema selemti
- Patrón: app/Services/Inventory/ReceptionService.php

PASO 1: CREAR MODELOS

A. app/Models/Rec/OrdenProduccion.php
```php
<?php
namespace App\Models\Rec;

use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class OrdenProduccion extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.ordenes_produccion';

    protected $fillable = [
        'receta_id',
        'lote_produccion',
        'cantidad_objetivo',
        'cantidad_real',
        'estado',
        'fecha_inicio',
        'fecha_fin',
        'notas',
        'created_by',
        'completed_by',
    ];

    protected $casts = [
        'cantidad_objetivo' => 'decimal:4',
        'cantidad_real' => 'decimal:4',
        'fecha_inicio' => 'datetime',
        'fecha_fin' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Relaciones
    public function receta()
    {
        return $this->belongsTo(Receta::class, 'receta_id');
    }

    public function detalles()
    {
        return $this->hasMany(OrdenProduccionDetalle::class, 'orden_id');
    }

    public function createdBy()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function completedBy()
    {
        return $this->belongsTo(User::class, 'completed_by');
    }

    // Estados posibles
    const ESTADO_PLANIFICADA = 'PLANIFICADA';
    const ESTADO_EN_PROCESO = 'EN_PROCESO';
    const ESTADO_COMPLETADA = 'COMPLETADA';
    const ESTADO_POSTEADA = 'POSTEADA';
    const ESTADO_CANCELADA = 'CANCELADA';
}
```

B. app/Models/Rec/OrdenProduccionDetalle.php
```php
<?php
namespace App\Models\Rec;

use Illuminate\Database\Eloquent\Model;
use App\Models\Inv\Item;
use App\Models\Catalogs\Unidad;

class OrdenProduccionDetalle extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.ordenes_produccion_det';
    public $timestamps = false;

    protected $fillable = [
        'orden_id',
        'item_id',
        'cantidad_teorica',
        'cantidad_real',
        'unidad_medida_id',
        'costo_unitario',
        'costo_total',
    ];

    protected $casts = [
        'cantidad_teorica' => 'decimal:4',
        'cantidad_real' => 'decimal:4',
        'costo_unitario' => 'decimal:4',
        'costo_total' => 'decimal:2',
    ];

    public function orden()
    {
        return $this->belongsTo(OrdenProduccion::class, 'orden_id');
    }

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id');
    }

    public function unidadMedida()
    {
        return $this->belongsTo(Unidad::class, 'unidad_medida_id');
    }
}
```

PASO 2: CREAR MIGRACIÓN
```php
<?php
// database/migrations/2025_11_26_120000_create_ordenes_produccion_tables.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up()
    {
        DB::connection('pgsql')->statement("
            CREATE TABLE IF NOT EXISTS selemti.ordenes_produccion (
                id SERIAL PRIMARY KEY,
                receta_id INTEGER NOT NULL REFERENCES selemti.recetas(id),
                lote_produccion VARCHAR(50),
                cantidad_objetivo NUMERIC(12,4) NOT NULL,
                cantidad_real NUMERIC(12,4),
                estado VARCHAR(20) NOT NULL DEFAULT 'PLANIFICADA',
                fecha_inicio TIMESTAMP,
                fecha_fin TIMESTAMP,
                notas TEXT,
                created_by INTEGER REFERENCES selemti.users(id),
                completed_by INTEGER REFERENCES selemti.users(id),
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW()
            );

            CREATE INDEX idx_ordenes_prod_receta ON selemti.ordenes_produccion(receta_id);
            CREATE INDEX idx_ordenes_prod_estado ON selemti.ordenes_produccion(estado);
            CREATE INDEX idx_ordenes_prod_fecha ON selemti.ordenes_produccion(fecha_inicio);

            CREATE TABLE IF NOT EXISTS selemti.ordenes_produccion_det (
                id SERIAL PRIMARY KEY,
                orden_id INTEGER NOT NULL REFERENCES selemti.ordenes_produccion(id) ON DELETE CASCADE,
                item_id INTEGER NOT NULL REFERENCES selemti.items(id),
                cantidad_teorica NUMERIC(12,4) NOT NULL,
                cantidad_real NUMERIC(12,4),
                unidad_medida_id INTEGER NOT NULL REFERENCES selemti.cat_unidades(id),
                costo_unitario NUMERIC(12,4) DEFAULT 0,
                costo_total NUMERIC(12,2) DEFAULT 0
            );

            CREATE INDEX idx_ordenes_prod_det_orden ON selemti.ordenes_produccion_det(orden_id);
            CREATE INDEX idx_ordenes_prod_det_item ON selemti.ordenes_produccion_det(item_id);
        ");
    }

    public function down()
    {
        DB::connection('pgsql')->statement("
            DROP TABLE IF EXISTS selemti.ordenes_produccion_det CASCADE;
            DROP TABLE IF EXISTS selemti.ordenes_produccion CASCADE;
        ");
    }
};
```

PASO 3: CREAR SERVICE
app/Services/Production/ProductionService.php

MÉTODOS REQUERIDOS:
1. createOrder(int $recetaId, float $cantidadObjetivo, ?string $lote = null): int
2. startOrder(int $ordenId): void
3. consumeIngredients(int $ordenId, array $consumos): void
4. completeOrder(int $ordenId, float $cantidadReal): void
5. postOrder(int $ordenId): void
6. cancelOrder(int $ordenId, string $razon): void

IMPLEMENTAR:
- Validaciones: stock disponible, versión publicada, estado correcto
- Transacciones: DB::transaction() en todos los métodos
- Movimientos: Registrar en selemti.mov_inv con ref_tipo='produccion'
- Batches: Crear batch para producto terminado al postear
- Costeo: Calcular costo real sumando insumos consumidos

ENTREGABLE:
- 2 modelos completamente funcionales
- 1 migración
- 1 service con 6 métodos implementados y documentados
- Confirmar que migración se ejecuta sin errores
```

---

### PROMPT PARA QWEN: VALIDAR BACKEND PRODUCCIÓN

```
TAREA: Validar backend de Producción creado por CODEX

VALIDAR:
1. Migración se ejecutó correctamente
2. Tablas existen con estructura correcta
3. Índices fueron creados
4. Foreign keys funcionan
5. Service usa transacciones correctamente
6. Lógica de negocio es correcta

PROBAR FLUJO COMPLETO:
1. Crear orden desde receta
2. Iniciar orden
3. Consumir insumos
4. Completar orden
5. Postear orden
6. Verificar movimientos en mov_inv
7. Verificar batch creado

ENTREGABLE:
- docs/VALIDATION/PRODUCCION_BACKEND_VALIDACION.md
- ✅ o ❌ para cada validación
- Issues encontrados (si los hay)
```

---

### PROMPT PARA CODEX - PARTE 2: UI PRODUCCIÓN

```
TAREA: Crear UI completa para módulo de Producción (SOLO DESPUÉS DE VALIDACIÓN DE BACKEND)

USAR DESIGN SYSTEM desde el principio: <x-card>, <x-button>, <x-badge>, <x-kpi-card>

COMPONENTES A CREAR:

1. resources/views/livewire/production/orders-index.blade.php
   + app/Livewire/Production/OrdersIndex.php
   - Listado con filtros (estado, receta, fechas)
   - 4 KPIs: Total órdenes, En proceso, Completadas hoy, Eficiencia promedio
   - Tabla con órdenes
   - Botón "Nueva orden"

2. resources/views/livewire/production/order-create.blade.php
   + app/Livewire/Production/OrderCreate.php
   - Selector de receta (solo publicadas)
   - Input cantidad objetivo
   - Preview insumos requeridos
   - Validación de stock

3. resources/views/livewire/production/order-detail.blade.php
   + app/Livewire/Production/OrderDetail.php
   - Info de orden
   - Tabla de insumos (teórico vs real)
   - Botones de acción según estado
   - Timeline de transiciones

4. resources/views/livewire/production/consume-modal.blade.php
   + app/Livewire/Production/ConsumeModal.php
   - Modal para registrar consumos
   - Inputs cantidad real
   - Diferencias con colores

5. resources/views/produccion.blade.php (REEMPLAZAR)
   - Ya NO "módulo en preparación"
   - Embebe @livewire('production.orders-index')

RUTAS (agregar a routes/web.php):
```php
Route::middleware(['auth'])->prefix('production')->name('production.')->group(function () {
    Route::get('/', \App\Livewire\Production\OrdersIndex::class)->name('orders.index');
    Route::get('/create', \App\Livewire\Production\OrderCreate::class)->name('orders.create');
    Route::get('/{id}', \App\Livewire\Production\OrderDetail::class)->name('orders.detail');
});
```

ENTREGABLE:
- 5 componentes Blade + PHP Livewire
- Rutas configuradas
- produccion.blade.php actualizado
- Documentación en docs/PRODUCTION/UI_IMPLEMENTATION.md
```

---

## 🎯 SECUENCIA DE EJECUCIÓN URGENTE

### DÍA 1 (HOY):
1. **QWEN**: Diagnóstico reportes (PARTE 1) - 4-6 horas
2. **Yo (CLAUDE)**: Validar diagnóstico y aprobar correcciones
3. **QWEN**: Ejecutar correcciones reportes (PARTE 2) - 2-3 horas

### DÍA 2:
4. **QWEN**: Validar inventarios y transferencias - 3-4 horas
5. **CODEX** (paralelo): Backend Producción (modelos + service) - 6-8 horas
6. **Yo (CLAUDE)**: Validar backend producción con reporte de QWEN

### DÍA 3:
7. **CODEX**: Corregir issues de inventarios (si los hay) - 2-3 horas
8. **CODEX**: UI Producción - 8-10 horas
9. **Yo (CLAUDE)**: Validar UI y funcionalidad completa

### DÍA 4:
10. **Pruebas finales** de todos los módulos
11. **Documentación** de cambios realizados
12. **Entrega** al usuario para testing

---

## 📊 MÉTRICAS DE ÉXITO

### Reportes:
✅ Cifras coinciden entre Dashboard y Reportes (diferencia < 1%)
✅ Vistas materializadas se refrescan automáticamente
✅ Documentado proceso de refresh

### Inventarios:
✅ Todos los flujos funcionan correctamente
✅ Movimientos se registran en mov_inv
✅ Batches se crean/actualizan correctamente

### Transferencias:
✅ Flujo completo funciona sin errores
✅ Movimientos de salida y entrada se registran
✅ Stock se actualiza correctamente

### Producción:
✅ Backend completo y funcional
✅ UI completa con 5 componentes
✅ Flujo completo probado y funcional
✅ Módulo listo para usar en producción

---

**ESTADO**: Listo para iniciar
**ESPERANDO**: Aprobación del usuario para comenzar con QWEN
