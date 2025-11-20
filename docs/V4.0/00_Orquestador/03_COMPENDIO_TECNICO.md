# COMPENDIO TÉCNICO V4.0

**Orquestador**: MAESTRO (Consolidación CLAUDE + QWEN + CODEX + COPILOT)
**Fecha**: 14 Noviembre 2025
**Audiencia**: Desarrolladores nuevos, Agentes IA
**Nivel**: Síntesis (10-12 páginas)

---

## 1. ¿QUÉ ES TERRENA?

Terrena es un **ERP/POS integral para restaurantes multi-sucursal** que integra gestión completa de operaciones gastronómicas, desde inventario hasta ventas, producción y finanzas.

### Alcance del Sistema

- 15 módulos integrados (Inventario, Recetas, Producción, Compras, POS, Ventas, Caja, Reportes, etc.)
- Multi-sucursal, multi-almacén
- Integración con POS legacy (Floreant POS)
- 147 tablas, 38 vistas, 37 funciones BD
- 80 modelos Eloquent, 58 componentes Livewire
- 76.7% de alineación general (FASE1-FASE6)

---

## 2. HISTORIA DEL PROYECTO

### Auditoría 13 Noviembre 2025 (6 fases)

| Fase | Alcance | Hallazgos Clave |
|------|---------|----------------|
| FASE1 | Árbol de archivos | 729 archivos, estructura modular confirmada |
| FASE2 | Docs V4.0 | 19/44 docs completos (76%), 25 faltantes |
| FASE3 | Docs legacy | 250+ archivos history, migración pendiente |
| FASE4 | Código | 479 archivos, 61% con doc, 39% huérfanos (189 archivos) |
| FASE5 | Base de Datos | 147 tablas, 38 vistas, 37 funciones, 12 críticas sin doc |
| FASE6 | UX | Score 6.5/10, gaps críticos (loading states, notificaciones, confirmaciones) |

### Estado Actual (Noviembre 2025)

- **Módulos Completos** (90-100%): Caja Chica, Caja, Reportes, Catálogos
- **Módulos Funcionales** (70-89%): Inventario, Recetas, Purchasing, Ventas, Seguridad
- **Módulos Parciales** (50-69%): Producción, POS, Transferencias, Finanzas
- **Gaps Críticos**:
  1. Motor Replenishment 0% implementado
  2. PosConsumptionService triplicado
  3. Forms sin loading states (40 forms)
  4. 12 funciones BD sin documentar
  5. ProductionService duplicado

---

## 3. STACK TECNOLÓGICO

### Backend

| Componente | Tecnología | Versión | Propósito |
|------------|------------|---------| ---------|
| Framework | Laravel | 12 | Framework MVC principal |
| Lenguaje | PHP | 8.2+ | Backend logic |
| Base de Datos | PostgreSQL | 9.5 | Dual schema (selemti + public) |
| Autenticación | JWT | tymon/jwt-auth | API authentication |
| Permisos | Spatie Laravel Permission | - | RBAC, 7 roles, 45 permisos |
| API Docs | L5-Swagger | - | OpenAPI 3.0 documentation |

### Frontend

| Componente | Tecnología | Versión | Propósito |
|------------|------------|---------| ---------|
| UI Framework | Livewire | 3.7 beta | Reactive components (58 componentes) |
| CSS Framework | Bootstrap | 5.3 | UI design system |
| CSS Legacy | Tailwind CSS | 3.x | Legacy (migrar a Bootstrap) |
| JavaScript | Alpine.js | 3.x | Interactividad ligera |
| Build Tool | Vite | - | Asset bundling, HMR |
| Charts | Chart.js | - | Data visualization |

### Deployment

| Aspecto | Local | Producción |
|---------|-------|------------|
| OS | Windows + XAMPP | Ubuntu 22.04 + Apache |
| DB | PostgreSQL 9.5 (puerto 5433) | PostgreSQL 14+ |
| URL | http://localhost/TerrenaLaravel | http://100.126.124.101/terrena2/ |
| Alias | - | `/terrena2` |
| RewriteBase | - | `/terrena2/` |

---

## 4. ARQUITECTURA

### 4.1 Dual Database Architecture

**PostgreSQL 9.5** (producción):
- Connection: `pgsql` → **OBLIGATORIO** en todos los modelos
- Esquemas:
  - **`selemti`**: Esquema de trabajo (modificable)
  - **`public`**: Floreant POS legacy (**READ-ONLY**, coordinación required)

**Convención Modelos**:
```php
<?php
namespace App\Models\Inv;

class Item extends Model
{
    protected $connection = 'pgsql';        // OBLIGATORIO
    protected $table = 'selemti.items';     // OBLIGATORIO con schema
    protected $guarded = [];
}
```

### 4.2 Estructura Proyecto

```
app/
├── Models/         (80 modelos Eloquent, 82 tablas sin modelo)
│   ├── Inv/        (Item, Batch, MovimientoInventario)
│   ├── Rec/        (Receta, RecetaDetalle, RecetaVersion)
│   ├── Pos/        (Ticket, MenuItem, MenuCategory)
│   ├── Purchasing/ (PurchaseRequest, PurchaseOrder)
│   └── CashFund/   (CashFund, CashFundMovement)
├── Services/       (34 servicios de negocio)
│   ├── Inventory/  (ReceptionService, TransferService, BatchTrackingService)
│   ├── Purchasing/ (PurchasingService, ReplenishmentService - 0% implementado)
│   ├── Recipes/    (RecipeService)
│   └── Caja/       (DailyCloseService, AlertasService)
├── Http/Controllers/ (64 controladores)
│   ├── Api/Caja/   (8 controladores)
│   └── Api/        (REST APIs)
├── Livewire/       (58 componentes UI)
│   ├── Inventory/  (8 componentes: Items, Recepciones, Conteos, Transfers)
│   ├── Purchasing/ (5 componentes: Requests, Orders)
│   ├── Recipes/    (2 componentes: RecipesIndex, RecipeEditor)
│   ├── CashFund/   (6 componentes: Create, Detail, Movements)
│   └── Reports/    (3 componentes: Dashboard, KPIs)
└── Helpers/        (CajaHelper.php global)

database/
├── migrations/     (76 migraciones, 26 sin doc)
└── seeders/        (Permisos, roles, datos iniciales)

resources/
├── views/          (167 vistas Blade)
│   ├── layouts/    (terrena.blade.php - Bootstrap 5)
│   └── livewire/   (Componentes Livewire)
├── css/            (Bootstrap + componentes)
└── js/             (Alpine.js + Vite)

routes/
├── web.php         (Rutas Livewire + páginas estáticas)
└── api.php         (REST APIs - /api/caja/*, /api/unidades/*)

docs/
└── V4.0/           (Documentación canónica - única fuente de verdad)
    ├── Guia/       (Stack.md, Deployment.md)
    ├── 00_Orquestador/ (Gobernanza sistema)
    │   ├── 00_CONTRATO_SISTEMA_TERRENA_v3.md
    │   ├── 01_MATRIZ_ALINEACION_V4.0.md
    │   ├── 02_BACKLOG_SPRINTS_V4.0.md
    │   └── 03_COMPENDIO_TECNICO.md (este archivo)
    ├── Inventario/ (Items.md - 80% completo, faltan Lotes, Kardex, Ajustes)
    ├── Recetas/    (README.md - 70%, faltan Versionado, BOM Implosion)
    ├── Purchasing/ (2 docs - 85%, falta Replenishment)
    ├── Caja/       (3 docs - 95%)
    ├── Reports/    (README.md - 90%)
    └── [15 módulos total]
```

---

## 5. MÓDULOS CORE

### Diagrama de Conexiones

```
[POS] ↔ [Recetas] ↔ [Inventario] ↔ [Producción]
   ↓         ↓          ↓              ↓
[Ventas]  [Costeo]  [Compras]     [Mermas]
   ↓         ↓          ↓              ↓
[Reportes] [Caja]  [Replenishment] [KPIs]
   ↑         ↑          ↑              ↑
[Finanzas] [CajaChica] [Transferencias] [Catálogos]
```

### 5.1 INVENTARIO (84% alineado)

**Estado**: 🟢 Funcional, gaps menores

**Componentes Clave**:
- **Models**: Item, Batch, MovimientoInventario, Stock
- **Services**: ReceptionService, TransferService, BatchTrackingService (sin doc)
- **Livewire**: ItemsIndex, ReceptionsIndex, ReceptionCreate, CountsIndex, TransferCreate (8 total)
- **Tablas BD**: items, mov_inv (kardex), inventory_batch, stock, lotes
- **Vistas BD**: vw_stock_por_lote_fefo (FEFO implementado)

**Funcionalidades**:
- ✅ Alta de ítems (completo)
- ✅ Recepciones (wizard básico)
- ⚠️ Recepciones estados (falta BORRADOR → VALIDADA → POSTEADA)
- ⚠️ Recepciones tolerancias (no implementado)
- ❌ Recepciones evidencias (fotos/docs no implementado)
- ✅ Conteos físicos (completo)
- ⚠️ Transferencias (solo creación, falta despacho/recepción UI)
- ✅ Kardex (completo)
- ⚠️ Mermas/Ajustes (funcionalidad limitada, sin catálogo motivos)

**Gaps Críticos**:
- 4 docs faltantes: Lotes, Kardex, Ajustes, Políticas
- InventoryAdjustmentService sin doc
- BatchTrackingService sin doc
- 8 componentes Livewire sin doc
- Forms sin loading states

**Deployment**: Verificar FEFO funcional en producción

---

### 5.2 RECETAS (75% alineado)

**Estado**: 🟡 Funcional con gaps

**Componentes Clave**:
- **Models**: Receta, RecetaDetalle, RecetaVersion, RecipeCostSnapshot (huérfano)
- **Services**: RecipeService
- **Livewire**: RecipesIndex, RecipeEditor (2 total)
- **Tablas BD**: receta_cab, receta_det, receta_version, receta_insumo, recipe_cost_snapshots
- **Funciones BD**: fn_recipe_cost_at() (sin doc, CRÍTICO para producción)

**Funcionalidades**:
- ✅ Editor básico (completo)
- ✅ Subrecetas (completo)
- ⚠️ Versionado - Estructura BD (completo)
- ❌ Versionado - UI (no implementado)
- ❌ Versionado - Lógica (editor solo version=1)
- ✅ Costeo automático (completo)
- ⚠️ Costeo histórico (API no expuesta)
- ⚠️ Snapshots (job no programado)
- ✅ Catálogo UOM (completo)
- ✅ Conversiones UOM (completo)

**Gaps Críticos**:
- Documentación muy breve (135 líneas)
- Sistema versionado no documentado, UI no existe
- Naming duplicado: receta_version vs recipe_versions
- RecipeCostSnapshot modelo huérfano
- BOM Implosion no completamente funcional

**Deployment**: fn_recipe_cost_at() **CRÍTICO** para costeo en producción

---

### 5.3 PRODUCCIÓN (63% alineado)

**Estado**: 🟡 Parcial, gaps significativos

**Componentes Clave**:
- **Models**: OrdenProduccion, ProductionSchedule
- **Services**: ProductionService (**DUPLICADO** en 2 ubicaciones - CRÍTICO)
- **Livewire**: Kds/Board (solo KDS, falta UI operativa)
- **Tablas BD**: production_orders, op_cab, op_det, prod_cab, prod_det (4 tablas vacías)

**Funcionalidades**:
- ⚠️ Servicio backend (completo pero duplicado)
- ⚠️ API REST (endpoints no completos)
- ❌ CRUD órdenes (UI faltante)
- ❌ KPIs rendimiento (dashboard faltante)
- ❌ Mermas producción (registro no implementado)
- ❌ Mise en place (no en scope actual)

**Gaps Críticos**:
- ProductionService DUPLICADO (2 ubicaciones) - CRÍTICO
- Documentación mínima (100 líneas)
- UI operativa NO EXISTE
- 4 tablas sin uso (op_produccion_cab, sol_prod_*, prod_*)
- Módulo 60% implementado

**Deployment**: Consolidar ProductionService antes de deployment

---

### 5.4 PURCHASING (85% alineado, 31% sin motor replenishment)

**Estado**: 🔴 CRÍTICO - Motor Replenishment 0% implementado

**Componentes Clave**:
- **Models**: PurchaseRequest (**duplicado** - app/Models/ y app/Models/Purchasing/), PurchaseOrder
- **Services**: PurchasingService (Codex), **ReplenishmentService (0% implementado - CRÍTICO)**
- **Livewire**: Requests/Index, Requests/Create, Requests/Detail, Orders/Index, Orders/Detail (5 total)
- **Tablas BD**: purchase_requests (64 kB), purchase_orders (40 kB), purchase_suggestions (90 registros)

**Funcionalidades**:
- ✅ Solicitudes CRUD (completo)
- ✅ POs CRUD (completo)
- ❌ Cotizaciones (módulo faltante)
- ❌ Devoluciones (módulo incompleto)
- ❌ Políticas stock (motor no implementado) - **CRÍTICO**
- ❌ Algoritmo Min-Max (no implementado) - **CRÍTICO**
- ❌ Algoritmo SMA (no implementado) - **CRÍTICO**
- ❌ POS Consumption algorithm (no implementado) - **CRÍTICO**
- ❌ Dashboard sugerencias (no implementado) - **CRÍTICO**
- ❌ API Sugerencias (no implementada) - **CRÍTICO**

**Gaps Críticos**:
- **Motor Replenishment 0% implementado** (CRÍTICO - Sprint 2)
- PurchaseRequest duplicado
- 7 algoritmos y features sin implementar
- Doc de Reposición Automática faltante

**Deployment**: Motor completo requerido en producción

---

### 5.5 POS (70% alineado)

**Estado**: 🟡 Funcional con gaps críticos

**Componentes Clave**:
- **Models**: Ticket, MenuItem, MenuCategory, PosMap (huérfano)
- **Services**: **PosConsumptionService (TRIPLICADO - CRÍTICO)**, 5 repositorios sin doc
- **Tablas BD**: ticket_venta_cab, ticket_venta_det, pos_map (40 kB), menu_items (24 kB), 10 tablas sin modelo
- **Funciones BD**: fn_expandir_consumo_ticket, fn_confirmar_consumo, fn_reversar_consumo (sin doc)

**Funcionalidades**:
- ✅ Mapeo POS-Recetas (completo)
- ⚠️ Mapeo modificadores (UI faltante)
- ⚠️ Consumo automático (UI limitada)
- ⚠️ Reproceso tickets (UI faltante)
- ⚠️ Auditoría consumos (dashboard limitado)
- ❌ API Recipe Cost (no en routes)

**Gaps Críticos**:
- PosConsumptionService **TRIPLICADO** (3 ubicaciones) - CRÍTICO
- Documentación muy breve (110 líneas)
- 5 repositorios sin documentar
- 10 tablas sin modelo (pos_sync_logs, pos_reprocess_log, etc.)

**Deployment**: Consolidar PosConsumptionService en producción, fn_expandir_consumo_ticket() funcional

---

### 5.6 CAJA (94% alineado)

**Estado**: ✅ EXCELENTE - Módulo modelo

**Componentes Clave**:
- **Models**: SesionCajon, Precorte, Postcorte, Terminal, FormasPago (12 total)
- **Services**: AlertasService (sin doc)
- **Controllers**: 8 controladores Api/Caja/
- **Helpers**: CajaHelper.php (qp, J, ver)
- **Tablas BD**: sesion_cajon (152 kB, 132 sesiones), precorte, postcorte, formas_pago
- **UI**: _wizard_modals.blade.php (completo)

**Funcionalidades**:
- ✅ Sesiones cajón (completo)
- ✅ Precorte (completo)
- ✅ Postcorte (completo)
- ✅ Conciliación efectivo (completo)
- ✅ Conciliación tarjetas (completo)
- ✅ Histórico UI (completo)
- ⚠️ Alertas cortes (dashboard mejorable)

**Gaps Menores**:
- AlertasService sin documentar
- Forms sin loading states

**Deployment**: Validar triggers precorte/postcorte en producción

---

### 5.7 CAJA CHICA (100% alineado)

**Estado**: ✅ PERFECTO - Módulo modelo ejemplar

**Componentes Clave**:
- **Models**: CashFund, CashFundMovement, CashFundSettlement (6 total)
- **Services**: CashFundService (completo)
- **Livewire**: 6 componentes (Create, Detail, Movements, Settlements, Approvals, Index)
- **Tablas BD**: cash_funds (96 kB, 1 registro), cash_fund_movements, cash_fund_arqueos
- **Docs**: 13 docs en /CajaChica/FondoCaja/ (100%)

**Funcionalidades**:
- ✅ Fondo de Caja (completo)
- ✅ Movimientos (completo)
- ✅ Arqueos (completo)
- ✅ Cierres Diarios (completo)

**Deployment**: Validar flujo completo en producción

---

### 5.8 REPORTES (94% alineado)

**Estado**: ✅ EXCELENTE

**Componentes Clave**:
- **Controllers**: 8 controladores
- **Vistas BD**: 38 vistas (vw_sesion_dpr, vw_dashboard_*, vw_report_sales_*)
- **Migraciones**: 77 migraciones UOM
- **Livewire**: 3 componentes (Dashboard, KPIs, Analytics)

**Funcionalidades**:
- ✅ Dashboard principal (completo)
- ✅ KPIs sucursal (completo)
- ✅ KPIs terminal (completo)
- ✅ 15 reportes de ventas (completos)
- ⚠️ Export PDF/XLSX (incompletas)

**Gaps Menores**:
- 10 vistas BD sin doc individual
- Exportaciones avanzadas limitadas

**Deployment**: Validar vistas de dashboard en producción, verificar rendimiento

---

### 5.9 CATÁLOGOS (89% alineado)

**Estado**: ✅ EXCELENTE

**Componentes Clave**:
- **Livewire**: 6 componentes (Unidades, Almacenes, Proveedores, Sucursales, Políticas, Categorías)
- **Tablas BD**: cat_unidades, cat_almacenes, cat_proveedores, cat_sucursales

**Funcionalidades**:
- ✅ Unidades medida (completo)
- ✅ Conversiones UOM (completo)
- ✅ Proveedores (completo)
- ✅ Almacenes (completo)
- ✅ Sucursales (completo)
- ⚠️ Políticas stock (UI sin motor)

**Deployment**: Validar conversiones de unidades, integridad referencial

---

### 5.10 TRANSFERENCIAS (68% alineado)

**Estado**: 🟡 Funcional con gaps UI

**Componentes Clave**:
- **Services**: TransferService (completo)
- **Livewire**: TransferCreate (solo creación, falta despacho/recepción)
- **Tablas BD**: transfer_cab, transfer_det
- **Controllers**: TransferApiController (huérfano, no en routes)

**Funcionalidades**:
- ✅ Estados - SOLICITADA (completo)
- ⚠️ Estados - DESPACHADA (UI faltante)
- ⚠️ Estados - RECIBIDA (UI faltante)
- ❌ API REST (endpoints no implementados)

**Gaps Críticos**:
- UI solo creación, sin despacho/recepción
- Solo 2 de 5 estados implementados
- TransferApiController huérfano

**Deployment**: Implementar UI despacho/recepción en servidor

---

## 6. GAPS CRÍTICOS (Top 5)

### GAP #1: Motor Replenishment 0% (CRÍTICO)

**Módulo**: Purchasing
**Severidad**: 🔴 P0
**Impacto**: Operación de compras completamente manual
**Esfuerzo**: 31 horas (Sprint 2)

**Faltante**:
- Algoritmo Min-Max (12h)
- Algoritmo SMA (Simple Moving Average)
- Algoritmo POS Consumption
- Dashboard sugerencias (10h)
- API Sugerencias (9h)
- Razón de cálculo (trazabilidad)

**Deployment**: Motor completo requerido en producción

---

### GAP #2: PosConsumptionService x3 (CRÍTICO)

**Módulo**: POS
**Severidad**: 🔴 P0
**Impacto**: Código inconsistente, difícil mantenimiento
**Esfuerzo**: 4 horas (Sprint 1)

**Ubicaciones**:
1. app/Services/Pos/PosConsumptionService.php (mantener)
2. app/Services/PosConsumptionService.php (eliminar)
3. app/Services/Legacy/PosConsumptionService.php (eliminar)

**Deployment**: Consolidar en producción antes de eliminar copias

---

### GAP #3: Forms sin Loading States (CRÍTICO UX)

**Módulo**: Frontend
**Severidad**: 🔴 P0
**Impacto**: UX pobre, riesgo doble submit
**Esfuerzo**: 4 horas (Sprint 1)

**Faltante**:
- 40 formularios sin wire:loading
- Patrón loading state unificado
- Spinners + texto "Guardando..."
- Botón deshabilitado durante submit

**Deployment**: Validar en servidor con RewriteBase /terrena2/

---

### GAP #4: 12 Funciones BD Sin Documentar (CRÍTICO)

**Módulo**: Base de Datos
**Severidad**: 🔴 P0
**Impacto**: Operación, mantenimiento difícil
**Esfuerzo**: 20 horas (Sprint 2)

**Funciones Críticas**:
1. fn_recipe_cost_at() - Costeo de recetas (CRÍTICO para producción)
2. fn_expandir_consumo_ticket() - Expansión de consumos POS
3. fn_confirmar_consumo() - Confirmación de consumos
4. fn_reversar_consumo() - Reversión de consumos
5. fn_consolidar_stock() - Consolidación de stock
6. fn_precorte_after_insert() - Trigger precorte
7. fn_postcorte_after_insert() - Trigger postcorte
8. [... 5 más]

**Deployment**: Validar que funciones existan en producción

---

### GAP #5: ProductionService x2 (ALTA)

**Módulo**: Producción
**Severidad**: 🟡 P1
**Impacto**: Código duplicado, inconsistencia
**Esfuerzo**: 3 horas (Sprint 1)

**Ubicaciones**:
1. app/Services/Production/ProductionService.php (mantener)
2. app/Services/ProductionService.php (eliminar)

**Deployment**: Consolidar antes de deployment

---

## 7. HELPERS Y UTILIDADES

### CajaHelper.php (Global)

**Ubicación**: app/Helpers/CajaHelper.php (auto-loaded via composer.json)

**Funciones**:
```php
// Leer parámetro de query o body (flexible)
qp(Request $request, string $key, $default = null)

// JSON response shorthand
J(array $data, int $code = 200): JsonResponse

// Variance check para reconciliación
ver(float $difference): string  // 'CUADRA', 'A_FAVOR', 'EN_CONTRA'
```

**Uso**:
```php
use function App\Helpers\qp;
use function App\Helpers\J;

$terminalId = qp($request, 'terminal_id');  // lee de query o body
return J(['ok' => true, 'data' => $result]);
```

---

## 8. CONVENCIONES Y PATRONES

### API Response Standard

Todos los API responses usan `ApiResponseMiddleware`:

```php
// Success
return response()->json([
    'ok' => true,
    'data' => $result,
    'timestamp' => now()->toIso8601String()
]);

// Error
return response()->json([
    'ok' => false,
    'error' => 'error_code',
    'message' => 'Human readable message',
    'timestamp' => now()->toIso8601String()
], 400);
```

**Headers**:
- `X-API-Version: 2.0`
- CORS habilitado en local

### Inventory Transactions Pattern

```php
DB::transaction(function() use ($data) {
    // 1. Create header
    $reception = Reception::create($header);

    // 2. Create lines
    foreach ($data['lines'] as $line) {
        $receptionLine = ReceptionLine::create($line);

        // 3. Record in kardex (mov_inv)
        MovimientoInventario::create([
            'item_id' => $line['item_id'],
            'batch_id' => $batch->id,
            'tipo' => 'RECEPCION',
            'qty' => $line['qty_normalized'],  // base UOM
            'uom' => $item->base_uom,
            'ref_tipo' => 'RECEPTION',
            'ref_id' => $reception->id,
            'ts' => now()
        ]);
    }
});
```

**Regla de Oro**: Siempre normalizar cantidades a base UOM antes de registrar en kardex.

### Livewire Component Pattern

```php
use Livewire\Component;

class ItemsIndex extends Component
{
    public $items;
    public $search = '';

    protected $listeners = ['itemCreated' => 'refreshItems'];

    public function mount()
    {
        $this->refreshItems();
    }

    public function updatedSearch()
    {
        $this->refreshItems();
    }

    public function refreshItems()
    {
        $this->items = Item::where('nombre', 'like', "%{$this->search}%")
            ->orderBy('nombre')
            ->get();
    }

    public function render()
    {
        return view('livewire.inventory.items-index');
    }
}
```

**Blade View**:
```blade
<div>
    <input type="text" wire:model.live="search" placeholder="Buscar...">

    <button wire:click="refreshItems" wire:loading.attr="disabled">
        <span wire:loading.remove>Actualizar</span>
        <span wire:loading>Cargando...</span>
    </button>

    <table>
        @foreach ($items as $item)
            <tr>
                <td>{{ $item->codigo }}</td>
                <td>{{ $item->nombre }}</td>
            </tr>
        @endforeach
    </table>
</div>
```

---

## 9. DEPLOYMENT

### Pre-Deployment Checklist

```bash
# Tests
php artisan test

# Code style
./vendor/bin/pint

# Database
php artisan migrate:status

# Assets
npm run build

# Cache
php artisan config:clear
php artisan view:clear
php artisan route:clear
```

### Post-Deployment Checklist

```bash
# Production
sudo -u www-data composer install --no-dev
sudo -u www-data php artisan migrate --force
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan view:cache
sudo -u www-data php artisan route:cache
sudo chown -R www-data:www-data storage/
sudo chmod -R 775 storage/
```

### URLs de Validación

- **Local**: http://localhost/TerrenaLaravel
- **Producción (red local)**: http://192.168.1.235/terrena2/
- **Producción (VPN)**: http://100.126.124.101/terrena2/

### Validación Crítica en Producción

1. **Funciones BD**:
   ```sql
   SELECT proname FROM pg_proc WHERE proname LIKE 'fn_%';
   -- Verificar: fn_recipe_cost_at, fn_expandir_consumo_ticket, etc.
   ```

2. **Vistas**:
   ```sql
   SELECT viewname FROM pg_views WHERE schemaname = 'selemti';
   -- Verificar: vw_sesion_dpr, vw_stock_por_lote_fefo, etc.
   ```

3. **Permisos**:
   ```bash
   sudo -u www-data php artisan tinker
   >>> \Spatie\Permission\Models\Role::count()  # 7 roles
   >>> \Spatie\Permission\Models\Permission::count()  # 45 permisos
   ```

---

## 10. PRÓXIMOS PASOS

### Roadmap 8 Sprints (340h / 4 meses)

| Sprint | Horas | Enfoque | Objetivo |
|--------|-------|---------|----------|
| **S1** | 55h | UX Crítico + Consolidación | Forms loading, notificaciones, consolidar PosConsumptionService x3, ProductionService x2 |
| **S2** | 51h | Motor Replenishment + BD | Motor completo (31h), documentar 12 funciones BD (20h) |
| **S3** | 42h | Documentación Core | 15 docs V4.0 completos |
| **S4** | 40h | Código Huérfano | Eliminar duplicados, crear modelos faltantes |
| **S5** | 48h | Recetas + Transferencias | Versionado UI, Transferencias flujo completo |
| **S6** | 42h | Reportes + Inventario | KPIs analíticos, ajustes rápidos |
| **S7** | 37h | Seguridad + Design System | GUI permisos, design system |
| **S8** | 25h | Tests + Deployment | Tests integración, validación producción |

### Hitos Clave

- **Fin S2**: Motor Replenishment operativo, funciones BD documentadas
- **Fin S4**: Código limpio (sin duplicados, sin huérfanos críticos)
- **Fin S6**: Funcionalidad completa (versionado, transferencias, KPIs)
- **Fin S8**: Deployment ready (tests, validación, docs completas)

---

## 11. RECURSOS Y REFERENCIAS

### Documentación Oficial

- `docs/V4.0/Guia/Stack.md` - Stack completo y convenciones
- `docs/V4.0/Guia/Deployment.md` - Proceso de deployment
- `docs/V4.0/00_Orquestador/00_CONTRATO_SISTEMA_TERRENA_v3.md` - Contrato maestro
- `docs/V4.0/00_Orquestador/01_MATRIZ_ALINEACION_V4.0.md` - Estado de 15 módulos
- `docs/V4.0/00_Orquestador/02_BACKLOG_SPRINTS_V4.0.md` - Roadmap 8 sprints

### Multi-Agent Coordination

**Claude Code** (UI/UX):
- Livewire components, Blade views, frontend integration
- Configuración: `.claude/`

**Codex** (Backend):
- Service layer, business logic, API development
- Backend PRs merged from separate branches

**Gemini CLI** (Database):
- PostgreSQL operations on `selemti` schema
- Configuración: `.gemini/GEMINI.md`, `.gemini/WORK_ASSIGNMENTS.md`

### Common Pitfalls

1. **Forgetting `protected $connection = 'pgsql';`** en modelos PostgreSQL
2. **Hard-coding URLs** - usar named routes y `url()` helper
3. **Skipping transactions** para operaciones multi-tabla
4. **Not normalizing UOM quantities** antes de kardex
5. **Creating UI before validating backend** - verificar Service, models, BD primero
6. **Wrong layout** - usar `terrena.blade.php` (Bootstrap 5), no `app.blade.php` (Tailwind legacy)
7. **Modifying `public` schema** sin coordinación - es Floreant POS producción

---

**FIN COMPENDIO TÉCNICO V4.0 - MAESTRO**
