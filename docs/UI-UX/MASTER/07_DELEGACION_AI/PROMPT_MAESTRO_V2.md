# 🎯 PROMPT MAESTRO V2 - OPTIMIZADO PARA DELEGACIÓN

**Versión**: 2.0  
**Fecha**: 31 de octubre de 2025  
**Proyecto**: TerrenaLaravel ERP  
**Changelog**: Optimizado para copy-paste, variables claramente marcadas, ejemplos mejorados

---

## 🚀 QUICK START

### Para Delegar una Tarea:
1. **Copia** el bloque "PROMPT COMPLETO LISTO PARA USAR" (abajo)
2. **Busca y reemplaza** todas las variables `{MARCADAS_ASÍ}` con tus valores
3. **Adjunta** los documentos relevantes de `docs/UI-UX/MASTER/`
4. **Pega** en tu IA favorita (Claude, Qwen, ChatGPT, etc.)
5. **Valida** el resultado con `CHECKLIST_VALIDACION.md`

---

## 📋 VARIABLES A REEMPLAZAR

Antes de copiar el prompt, define estos valores:

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `{MODULO}` | Módulo principal | Inventario, Compras, Recetas |
| `{COMPONENTE}` | Componente específico | ItemsService, InventoryController |
| `{DESCRIPCION_TAREA}` | Qué debe hacer | "Crear servicio de transferencias entre almacenes" |
| `{CONTEXTO_NEGOCIO}` | Por qué es importante | "Crítico para multi-almacén, debe ser atómico" |
| `{MODELOS}` | Modelos Eloquent involucrados | TransferHeader, TransferDetail, Item |
| `{RUTAS}` | Rutas web o API | Route::resource('transfers', ...) |
| `{VALIDACIONES}` | Reglas de validación | warehouse_from_id: required\|exists:warehouses |
| `{PERMISOS}` | Permisos Spatie necesarios | transfers.view, transfers.create |
| `{TABLAS_BD}` | Tablas de BD involucradas | transfer_header, transfer_detail |
| `{CRITERIOS_ACEPTACION}` | Lista de criterios funcionales | Usuario puede crear transferencia, stock se actualiza |
| `{ARCHIVOS_CREAR}` | Archivos nuevos a crear | app/Services/TransferService.php |
| `{ARCHIVOS_MODIFICAR}` | Archivos existentes a modificar | routes/web.php, PermissionSeeder.php |
| `{REFERENCIAS_INTERNAS}` | Código similar en el proyecto | Ver CashFundService.php para patrón similar |

---

## 📄 PROMPT COMPLETO LISTO PARA USAR

```markdown
# 🎯 TAREA DE DESARROLLO - TERRENA LARAVEL ERP

## CONTEXTO DEL PROYECTO

**Proyecto**: TerrenaLaravel  
**Tipo**: ERP para restaurantes  
**Stack**: Laravel 11, Livewire 3, Alpine.js, Tailwind CSS, PostgreSQL 9.5  
**POS Integrado**: FloreantPOS  

### Funcionalidades Core
- Gestión de inventario multi-almacén
- Compras automatizadas (reposición inteligente)
- Recetas versionadas multinivel
- Producción con trazabilidad
- Caja chica y gastos
- Reportería avanzada

### Estado Actual del Proyecto
| Área | Completitud | Estado |
|------|-------------|--------|
| Base de Datos | 90% | ✅ Normalizada (Phases 2.1-2.4) |
| Backend Services | 65% | 🟡 Core OK, falta refinamiento |
| API REST | 75% | 🟡 Endpoints principales funcionan |
| Frontend Livewire | 60% | 🟡 Funcional, falta UX polish |
| Design System | 20% | 🔴 Por implementar |
| Testing | 30% | 🔴 Cobertura baja |

### Fases Recientes Completadas
- ✅ Phase 2.1-2.4: Consolidación BD (users, warehouses, items, recipes)
- ✅ Fase 3: Mejora integridad referencial
- ✅ Fase 4: Optimización performance
- ✅ Fase 5: Features enterprise (auditoría, soft deletes)

---

## ARQUITECTURA TÉCNICA

### Estructura de Carpetas
```
app/
├── Http/
│   ├── Controllers/        # Controladores web y API
│   └── Livewire/           # Componentes Livewire 3
├── Models/                 # Eloquent models
├── Services/               # Lógica de negocio (PATRÓN PRINCIPAL)
├── Jobs/                   # Async jobs (Redis)
├── Events/                 # Event system
└── Console/                # Artisan commands

resources/
├── views/
│   ├── livewire/          # Vistas Livewire
│   ├── components/        # Blade components reutilizables
│   └── layouts/           # app.blade.php, guest.blade.php
└── js/                    # Alpine.js, helpers JS

database/
├── migrations/            # Schema changes
├── seeders/              # Data population
└── factories/            # Testing factories

routes/
├── web.php               # Rutas UI (Livewire)
└── api.php               # Rutas API REST

docs/UI-UX/MASTER/        # 📚 DOCUMENTACIÓN PRINCIPAL
```

### Patrones de Diseño
1. **Servicios para lógica de negocio**: No poner lógica compleja en controllers
2. **Transacciones DB**: Usar `DB::transaction()` para operaciones multi-tabla
3. **Eager Loading**: Siempre usar `with()` para relaciones
4. **FormRequests**: Validación en clases dedicadas
5. **Eventos**: Para auditoría y side-effects
6. **Jobs**: Para procesamiento asíncrono (emails, reportes pesados)

### Base de Datos
- **Schema**: `selemti` (PostgreSQL 9.5)
- **Convenciones**:
  - FKs terminan en `_id`: `warehouse_id`, `user_id`
  - Timestamps: `created_at`, `updated_at` automáticos
  - Soft Deletes: `deleted_at` donde aplique
  - Auditoría: `created_by_user_id`, `updated_by_user_id`

---

## DOCUMENTACIÓN DISPONIBLE

**CRÍTICO**: Consulta estos documentos ANTES de empezar:

### Navegación Principal
📂 **MASTER Index**: `docs/UI-UX/MASTER/README.md`

### Por Tipo de Tarea

#### Backend
- `01_ESTADO_PROYECTO/01_BACKEND_STATUS.md` - Inventario completo backend
- `02_MODULOS/{MODULO}.md` - Specs del módulo específico
- `03_ARQUITECTURA/04_DATABASE_SCHEMA.md` - Schema BD consolidado
- `05_SPECS_TECNICAS/SERVICIOS_BACKEND.md` - Patrones de servicios
- `05_SPECS_TECNICAS/API_ENDPOINTS.md` - Convenciones API

#### Frontend
- `01_ESTADO_PROYECTO/02_FRONTEND_STATUS.md` - Inventario completo frontend
- `03_ARQUITECTURA/02_DESIGN_SYSTEM.md` - Componentes UI/UX
- `05_SPECS_TECNICAS/COMPONENTES_LIVEWIRE.md` - Patrones Livewire
- `05_SPECS_TECNICAS/COMPONENTES_BLADE.md` - Blade components

#### Base de Datos
- `docs/BD/Normalizacion/PROYECTO_100_COMPLETADO.md` - Normalización completa
- `03_ARQUITECTURA/04_DATABASE_SCHEMA.md` - Schema actualizado

#### Benchmarks
- `06_BENCHMARKS/` - Cómo lo hacen Oracle, Odoo, SAP, Toast, Square

---

## 🎯 TAREA ESPECÍFICA

### Módulo
**{MODULO}**

### Componente
**{COMPONENTE}**

### Descripción Detallada
{DESCRIPCION_TAREA}

**Ejemplo**:
```
Crear el servicio `TransferService` que maneje transferencias de inventario entre almacenes.

Debe incluir:
- Validación de stock disponible en almacén origen
- Creación de transacción (transfer_header + transfer_details)
- Actualización de stock en ambos almacenes (restar en origen, sumar en destino)
- Generación de eventos TransferCreated, TransferApproved para auditoría
- Manejo de errores con rollback completo
- Logging de operaciones críticas
```

### Contexto de Negocio
{CONTEXTO_NEGOCIO}

**Ejemplo**:
```
Las transferencias son críticas para operaciones multi-almacén en restaurantes.
Deben ser:
- Atómicas (todo o nada) - si falla algo, rollback completo
- Auditables - cada cambio debe quedar registrado
- Con aprobación - no se ejecutan automáticamente
- Trazables - historial completo de transferencias

El flujo es:
1. Usuario crea transferencia (status: 'pending')
2. Gerente aprueba (status: 'approved', stock se mueve)
3. O gerente rechaza (status: 'rejected', nada se mueve)
```

---

## ESPECIFICACIONES TÉCNICAS

### Modelos Eloquent Involucrados
{MODELOS}

**Ejemplo**:
```php
// MODELOS A USAR:
- App\Models\TransferHeader      (transfer_header table)
- App\Models\TransferDetail      (transfer_detail table)
- App\Models\Item                (items table)
- App\Models\Warehouse           (warehouses table)
- App\Models\User                (users table) - para auditoría
- App\Models\StockMovement       (stock_movements table) - para historial

// RELACIONES:
TransferHeader:
  - belongsTo(Warehouse, 'warehouse_from_id')
  - belongsTo(Warehouse, 'warehouse_to_id')
  - belongsTo(User, 'user_id')
  - hasMany(TransferDetail)

TransferDetail:
  - belongsTo(TransferHeader)
  - belongsTo(Item)
```

### Rutas/Endpoints
{RUTAS}

**Ejemplo**:
```php
// WEB ROUTES (routes/web.php)
Route::middleware(['auth'])->group(function() {
    Route::prefix('transfers')->name('transfers.')->group(function() {
        Route::get('/', [TransferController::class, 'index'])
            ->name('index')
            ->can('transfers.view');
        
        Route::get('/create', [TransferController::class, 'create'])
            ->name('create')
            ->can('transfers.create');
        
        Route::post('/', [TransferController::class, 'store'])
            ->name('store')
            ->can('transfers.create');
        
        Route::post('/{transfer}/approve', [TransferController::class, 'approve'])
            ->name('approve')
            ->can('transfers.approve');
        
        Route::post('/{transfer}/reject', [TransferController::class, 'reject'])
            ->name('reject')
            ->can('transfers.approve');
    });
});

// API ROUTES (routes/api.php)
Route::middleware(['auth:sanctum'])->group(function() {
    Route::apiResource('transfers', TransferApiController::class);
    Route::post('transfers/{transfer}/approve', [TransferApiController::class, 'approve']);
    Route::post('transfers/{transfer}/reject', [TransferApiController::class, 'reject']);
});
```

### Validaciones
{VALIDACIONES}

**Ejemplo**:
```php
// app/Http/Requests/StoreTransferRequest.php

public function rules(): array
{
    return [
        'warehouse_from_id' => 'required|exists:warehouses,id',
        'warehouse_to_id' => 'required|exists:warehouses,id|different:warehouse_from_id',
        'notes' => 'nullable|string|max:1000',
        'items' => 'required|array|min:1',
        'items.*.item_id' => 'required|exists:items,id',
        'items.*.quantity' => 'required|numeric|min:0.01',
        'items.*.unit_cost' => 'nullable|numeric|min:0',
    ];
}

public function withValidator($validator)
{
    $validator->after(function ($validator) {
        // Validación custom: verificar stock disponible
        foreach ($this->items as $index => $item) {
            $stock = StockService::getAvailableStock(
                $item['item_id'],
                $this->warehouse_from_id
            );
            
            if ($stock < $item['quantity']) {
                $validator->errors()->add(
                    "items.{$index}.quantity",
                    "Stock insuficiente. Disponible: {$stock}"
                );
            }
        }
    });
}
```

### Permisos (Spatie)
{PERMISOS}

**Ejemplo**:
```php
// database/seeders/PermissionSeeder.php

// AGREGAR ESTOS PERMISOS:
Permission::create(['name' => 'transfers.view', 'guard_name' => 'web']);
Permission::create(['name' => 'transfers.create', 'guard_name' => 'web']);
Permission::create(['name' => 'transfers.approve', 'guard_name' => 'web']);
Permission::create(['name' => 'transfers.delete', 'guard_name' => 'web']);

// ASIGNAR A ROLES:
$gerente = Role::findByName('gerente');
$gerente->givePermissionTo(['transfers.view', 'transfers.create', 'transfers.approve']);

$almacenista = Role::findByName('almacenista');
$almacenista->givePermissionTo(['transfers.view', 'transfers.create']);
```

### Tablas de Base de Datos
{TABLAS_BD}

**Ejemplo**:
```sql
-- transfer_header
CREATE TABLE selemti.transfer_header (
    id BIGSERIAL PRIMARY KEY,
    warehouse_from_id BIGINT NOT NULL REFERENCES selemti.warehouses(id),
    warehouse_to_id BIGINT NOT NULL REFERENCES selemti.warehouses(id),
    user_id BIGINT NOT NULL REFERENCES selemti.users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, approved, rejected
    notes TEXT,
    approved_by_user_id BIGINT REFERENCES selemti.users(id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP
);

-- transfer_detail
CREATE TABLE selemti.transfer_detail (
    id BIGSERIAL PRIMARY KEY,
    transfer_header_id BIGINT NOT NULL REFERENCES selemti.transfer_header(id) ON DELETE CASCADE,
    item_id BIGINT NOT NULL REFERENCES selemti.items(id),
    quantity NUMERIC(10,2) NOT NULL,
    unit_cost NUMERIC(10,2),
    total_cost NUMERIC(10,2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_transfer_header_status ON selemti.transfer_header(status);
CREATE INDEX idx_transfer_header_warehouses ON selemti.transfer_header(warehouse_from_id, warehouse_to_id);
CREATE INDEX idx_transfer_detail_item ON selemti.transfer_detail(item_id);
```

---

## ✅ CRITERIOS DE ACEPTACIÓN

### Funcionales
{CRITERIOS_ACEPTACION}

**Ejemplo**:
- [ ] Usuario puede crear transferencia seleccionando almacén origen y destino
- [ ] Usuario puede agregar múltiples items con cantidades
- [ ] Sistema valida stock disponible antes de guardar
- [ ] Gerente puede aprobar transferencia desde listado
- [ ] Al aprobar, stock se actualiza correctamente:
  - Resta en almacén origen
  - Suma en almacén destino
- [ ] Eventos se disparan correctamente (TransferCreated, TransferApproved)
- [ ] Historial de movimientos se registra en stock_movements
- [ ] Errores se manejan con mensajes claros al usuario
- [ ] Usuario puede ver listado de transferencias con filtros (status, fechas, almacén)
- [ ] Usuario puede ver detalle de transferencia (header + items)

### No Funcionales
- [ ] **Código sigue PSR-12**: Usar `./vendor/bin/pint` antes de entregar
- [ ] **Componentes reutilizables**: Extraer lógica común a servicios
- [ ] **Queries optimizadas**: Usar eager loading (`with()`)
- [ ] **Transacciones DB**: Operaciones críticas en `DB::transaction()`
- [ ] **Manejo de errores**: Try-catch completo, logs en `storage/logs/`
- [ ] **Comentarios mínimos**: Código auto-explicativo, PHPDoc en métodos públicos
- [ ] **Performance**: Queries <100ms, evitar N+1
- [ ] **Seguridad**: Validar permisos, sanitizar inputs

### Testing
- [ ] **Tests unitarios**: Para servicios y lógica de negocio crítica
- [ ] **Tests de integración**: Para controllers y flujo completo
- [ ] **Tests de validación**: Para FormRequests
- [ ] **Cobertura >80%**: Idealmente para servicios core

---

## 📦 ENTREGABLES ESPERADOS

### Archivos a CREAR
{ARCHIVOS_CREAR}

**Ejemplo**:
```
BACKEND:
- app/Services/TransferService.php
- app/Http/Controllers/TransferController.php
- app/Http/Controllers/Api/TransferApiController.php
- app/Http/Requests/StoreTransferRequest.php
- app/Http/Requests/UpdateTransferRequest.php
- app/Events/TransferCreated.php
- app/Events/TransferApproved.php
- app/Listeners/UpdateStockOnTransferApproved.php
- database/migrations/2025_10_31_000001_create_transfer_tables.php

FRONTEND:
- resources/views/transfers/index.blade.php
- resources/views/transfers/create.blade.php
- resources/views/transfers/show.blade.php
- app/Http/Livewire/TransferList.php
- app/Http/Livewire/TransferForm.php
- resources/views/livewire/transfer-list.blade.php
- resources/views/livewire/transfer-form.blade.php

TESTING:
- tests/Feature/TransferTest.php
- tests/Unit/TransferServiceTest.php
```

### Archivos a MODIFICAR
{ARCHIVOS_MODIFICAR}

**Ejemplo**:
```
- routes/web.php                          # Agregar rutas web
- routes/api.php                          # Agregar rutas API
- database/seeders/PermissionSeeder.php   # Agregar permisos
- config/app.php                          # Registrar listeners (si aplica)
- resources/views/layouts/navigation.blade.php  # Agregar link en menú
```

### Documentación a Actualizar
- [ ] **PHPDoc**: En todas las clases y métodos públicos
- [ ] **README del módulo**: `docs/UI-UX/MASTER/02_MODULOS/{MODULO}.md`
- [ ] **Changelog**: Anotar cambios importantes
- [ ] **API Docs**: Si hay nuevos endpoints, documentar en `05_SPECS_TECNICAS/API_ENDPOINTS.md`

---

## 🎨 GUÍAS DE ESTILO Y PATRONES

### Servicio (Lógica de Negocio)
```php
<?php

namespace App\Services;

use App\Models\TransferHeader;
use App\Models\TransferDetail;
use App\Events\TransferCreated;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class TransferService
{
    /**
     * Crear nueva transferencia entre almacenes
     *
     * @param array $data Datos validados del request
     * @return TransferHeader
     * @throws \Exception
     */
    public function createTransfer(array $data): TransferHeader
    {
        return DB::transaction(function () use ($data) {
            try {
                // 1. Crear header
                $transfer = TransferHeader::create([
                    'warehouse_from_id' => $data['warehouse_from_id'],
                    'warehouse_to_id' => $data['warehouse_to_id'],
                    'user_id' => auth()->id(),
                    'status' => 'pending',
                    'notes' => $data['notes'] ?? null,
                ]);

                // 2. Crear detalles
                foreach ($data['items'] as $item) {
                    $transfer->details()->create([
                        'item_id' => $item['item_id'],
                        'quantity' => $item['quantity'],
                        'unit_cost' => $item['unit_cost'] ?? 0,
                        'total_cost' => ($item['quantity'] * ($item['unit_cost'] ?? 0)),
                    ]);
                }

                // 3. Disparar evento
                event(new TransferCreated($transfer));

                Log::info("Transfer created", ['transfer_id' => $transfer->id]);

                return $transfer->load(['details.item', 'warehouseFrom', 'warehouseTo']);

            } catch (\Exception $e) {
                Log::error("Error creating transfer", [
                    'error' => $e->getMessage(),
                    'data' => $data,
                ]);
                throw $e;
            }
        });
    }

    /**
     * Aprobar transferencia y mover stock
     *
     * @param TransferHeader $transfer
     * @return TransferHeader
     * @throws \Exception
     */
    public function approveTransfer(TransferHeader $transfer): TransferHeader
    {
        if ($transfer->status !== 'pending') {
            throw new \Exception("Solo se pueden aprobar transferencias pendientes");
        }

        return DB::transaction(function () use ($transfer) {
            try {
                // 1. Actualizar status
                $transfer->update([
                    'status' => 'approved',
                    'approved_by_user_id' => auth()->id(),
                    'approved_at' => now(),
                ]);

                // 2. Mover stock (esto se hace en el listener)
                event(new TransferApproved($transfer));

                Log::info("Transfer approved", ['transfer_id' => $transfer->id]);

                return $transfer->refresh();

            } catch (\Exception $e) {
                Log::error("Error approving transfer", [
                    'transfer_id' => $transfer->id,
                    'error' => $e->getMessage(),
                ]);
                throw $e;
            }
        });
    }
}
```

### Controller (Web)
```php
<?php

namespace App\Http\Controllers;

use App\Models\TransferHeader;
use App\Services\TransferService;
use App\Http\Requests\StoreTransferRequest;
use Illuminate\Http\Request;

class TransferController extends Controller
{
    public function __construct(
        private TransferService $transferService
    ) {}

    public function index()
    {
        $this->authorize('transfers.view');

        $transfers = TransferHeader::with(['warehouseFrom', 'warehouseTo', 'user'])
            ->orderByDesc('created_at')
            ->paginate(20);

        return view('transfers.index', compact('transfers'));
    }

    public function create()
    {
        $this->authorize('transfers.create');

        $warehouses = Warehouse::orderBy('name')->get();
        $items = Item::orderBy('name')->get();

        return view('transfers.create', compact('warehouses', 'items'));
    }

    public function store(StoreTransferRequest $request)
    {
        try {
            $transfer = $this->transferService->createTransfer($request->validated());

            return redirect()
                ->route('transfers.show', $transfer)
                ->with('success', 'Transferencia creada exitosamente');

        } catch (\Exception $e) {
            return back()
                ->withInput()
                ->with('error', 'Error al crear transferencia: ' . $e->getMessage());
        }
    }

    public function approve(TransferHeader $transfer)
    {
        $this->authorize('transfers.approve');

        try {
            $this->transferService->approveTransfer($transfer);

            return back()->with('success', 'Transferencia aprobada');

        } catch (\Exception $e) {
            return back()->with('error', 'Error: ' . $e->getMessage());
        }
    }
}
```

### Livewire Component
```php
<?php

namespace App\Http\Livewire;

use App\Models\TransferHeader;
use Livewire\Component;
use Livewire\WithPagination;

class TransferList extends Component
{
    use WithPagination;

    public $search = '';
    public $status = '';

    protected $queryString = ['search', 'status'];

    public function updatingSearch()
    {
        $this->resetPage();
    }

    public function render()
    {
        $transfers = TransferHeader::query()
            ->with(['warehouseFrom', 'warehouseTo', 'user'])
            ->when($this->search, function($query) {
                $query->whereHas('warehouseFrom', function($q) {
                    $q->where('name', 'ILIKE', "%{$this->search}%");
                })->orWhereHas('warehouseTo', function($q) {
                    $q->where('name', 'ILIKE', "%{$this->search}%");
                });
            })
            ->when($this->status, function($query) {
                $query->where('status', $this->status);
            })
            ->orderByDesc('created_at')
            ->paginate(20);

        return view('livewire.transfer-list', compact('transfers'));
    }
}
```

### Vista Blade
```blade
{{-- resources/views/transfers/index.blade.php --}}
<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="text-xl font-semibold text-gray-800">Transferencias</h2>
            
            @can('transfers.create')
                <a href="{{ route('transfers.create') }}" 
                   class="btn btn-primary">
                    Nueva Transferencia
                </a>
            @endcan
        </div>
    </x-slot>

    <div class="py-6">
        <div class="max-w-7xl mx-auto px-4">
            @if(session('success'))
                <x-alert type="success">{{ session('success') }}</x-alert>
            @endif

            @livewire('transfer-list')
        </div>
    </div>
</x-app-layout>
```

### Migration
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('selemti.transfer_header', function (Blueprint $table) {
            $table->id();
            $table->foreignId('warehouse_from_id')->constrained('selemti.warehouses');
            $table->foreignId('warehouse_to_id')->constrained('selemti.warehouses');
            $table->foreignId('user_id')->constrained('selemti.users');
            $table->string('status', 20)->default('pending');
            $table->text('notes')->nullable();
            $table->foreignId('approved_by_user_id')->nullable()->constrained('selemti.users');
            $table->timestamp('approved_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['status', 'created_at']);
            $table->index(['warehouse_from_id', 'warehouse_to_id']);
        });

        Schema::create('selemti.transfer_detail', function (Blueprint $table) {
            $table->id();
            $table->foreignId('transfer_header_id')
                ->constrained('selemti.transfer_header')
                ->onDelete('cascade');
            $table->foreignId('item_id')->constrained('selemti.items');
            $table->decimal('quantity', 10, 2);
            $table->decimal('unit_cost', 10, 2)->nullable();
            $table->decimal('total_cost', 10, 2)->nullable();
            $table->timestamps();

            $table->index('item_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('selemti.transfer_detail');
        Schema::dropIfExists('selemti.transfer_header');
    }
};
```

---

## 🔍 VALIDACIÓN PRE-ENTREGA

### Checklist Técnico
Antes de entregar, ejecuta:

```bash
# 1. Linter PHP
./vendor/bin/pint

# 2. Clear cache
php artisan optimize:clear

# 3. Run migrations
php artisan migrate

# 4. Seed permisos (si aplica)
php artisan db:seed --class=PermissionSeeder

# 5. Verificar rutas
php artisan route:list | grep transfers

# 6. Run tests
php artisan test --filter=Transfer

# 7. Compilar assets (si hay cambios en frontend)
npm run build
```

### Checklist Funcional
- [ ] Código funciona localmente (probado manualmente)
- [ ] Todas las rutas renderizan correctamente
- [ ] Validaciones funcionan (probar casos edge)
- [ ] Permisos funcionan (probar con diferentes roles)
- [ ] Transacciones DB rollbackean correctamente en errores
- [ ] Eventos se disparan correctamente
- [ ] Logs se escriben en `storage/logs/laravel.log`
- [ ] No hay queries N+1 (revisar con Debugbar si está instalado)

### Checklist de Calidad
- [ ] Sin TODOs o FIXMEs críticos
- [ ] Variables de entorno documentadas (si hay nuevas)
- [ ] PHPDoc completo en métodos públicos
- [ ] Código auto-explicativo (nombres descriptivos)
- [ ] Performance aceptable (<100ms por request idealmente)
- [ ] Errores manejados con try-catch
- [ ] Mensajes de error claros para el usuario

---

## 🚨 RESTRICCIONES Y WARNINGS

### ❌ NO HACER NUNCA
- **No eliminar código funcional** sin confirmar con humano
- **No cambiar schema BD existente** sin migración explícita
- **No usar queries N+1** (siempre usar `with()` o `load()`)
- **No hardcodear valores** (usar config/, .env, o constantes)
- **No exponer datos sensibles** en logs o respuestas API
- **No usar jQuery** (usar Alpine.js o JavaScript vanilla)
- **No mezclar lógica de negocio en controllers** (usar servicios)
- **No commitear archivos de configuración** (.env, IDE configs)

### ✅ SIEMPRE HACER
- **Usar transacciones DB** para operaciones multi-tabla
- **Validar permisos** en controllers (`$this->authorize()`)
- **Sanitizar inputs** con FormRequests
- **Manejar errores** con try-catch y logging
- **Eager load** relaciones cuando sea necesario
- **Seguir convenciones** del proyecto (PSR-12, Laravel best practices)
- **Escribir tests** para lógica crítica
- **Documentar APIs** si se crean nuevos endpoints

### ⚠️ CONSIDERACIONES ESPECIALES

#### PostgreSQL 9.5
- No usar features de PG 10+ (ej: `IDENTITY COLUMNS`)
- Probar queries con `EXPLAIN ANALYZE`
- Usar `ILIKE` para búsquedas case-insensitive

#### Livewire 3
- Propiedades públicas deben ser "wireable" (primitivos, arrays, Eloquent collections)
- Usar `wire:model.live` para reactividad en tiempo real
- Evitar lógica pesada en `render()`, moverla a métodos dedicados

#### Performance
- Queries <100ms idealmente
- Usar caché para datos que no cambian frecuentemente
- Jobs para procesamiento pesado (reportes, emails)

---

## 📚 REFERENCIAS INTERNAS

### Código Similar en el Proyecto
{REFERENCIAS_INTERNAS}

**Ejemplo**:
```
SERVICIOS SIMILARES:
- app/Services/CashFundService.php
  - Patrón de transacciones DB
  - Manejo de eventos
  - Validaciones custom

CONTROLLERS SIMILARES:
- app/Http/Controllers/InventoryController.php
  - Estructura de CRUD completo
  - Manejo de permisos
  - Redirecciones y mensajes flash

LIVEWIRE SIMILARES:
- app/Http/Livewire/CashFundMovementList.php
  - Paginación y búsqueda
  - Filtros dinámicos
  - Exportación a Excel

VISTAS SIMILARES:
- resources/views/inventory/index.blade.php
  - Layout base para listados
  - Tabla responsive
  - Componentes reutilizables
```

### Documentación Externa
- [Laravel 11 Docs](https://laravel.com/docs/11.x)
- [Livewire 3 Docs](https://livewire.laravel.com/docs)
- [Alpine.js Docs](https://alpinejs.dev/)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [Spatie Laravel Permission](https://spatie.be/docs/laravel-permission)
- [PostgreSQL 9.5 Docs](https://www.postgresql.org/docs/9.5/)

---

## 💡 TIPS DE EFICIENCIA PARA IAs

### Antes de Empezar
1. **Lee el schema**: `03_ARQUITECTURA/04_DATABASE_SCHEMA.md` para relaciones
2. **Busca ejemplos**: Siempre hay código similar que puedes adaptar
3. **Revisa el módulo**: `02_MODULOS/{MODULO}.md` para contexto completo
4. **Consulta benchmarks**: `06_BENCHMARKS/` para mejores prácticas

### Durante el Desarrollo
- **Sigue patrones existentes**: No inventes, adapta lo que ya funciona
- **Eager load**: Usa `with()` para relaciones usadas en vistas
- **Transacciones**: Envuelve operaciones multi-tabla en `DB::transaction()`
- **Loguea errores**: `Log::error()` con contexto suficiente
- **Valida temprano**: FormRequests antes de llegar al servicio

### Debugging Común

#### Error: Foreign key constraint violation
**Causa**: Intentando insertar FK que no existe
**Solución**: Verificar que el ID referenciado existe, usar `exists:tabla,columna` en validaciones

#### Error: Livewire component not updating
**Causa**: Propiedad no es "wireable" o falta `wire:model`
**Solución**: Usar tipos primitivos en propiedades públicas, o implementar `Wireable`

#### Error: Permission denied
**Causa**: Permisos no seedeados o usuario sin rol
**Solución**: Re-seedear `PermissionSeeder`, asignar roles correctos

#### Error: Query timeout
**Causa**: N+1 queries o falta de índices
**Solución**: Usar `with()`, agregar índices en migration

---

## 📞 SOPORTE Y ESCALACIÓN

### Si Encuentras Problemas

#### 1. Inconsistencias en Documentación
```markdown
🐛 INCONSISTENCIA ENCONTRADA

**Ubicación**: docs/UI-UX/MASTER/02_MODULOS/Inventario.md, línea 45
**Problema**: Dice que el modelo es `Product` pero en el código es `Item`
**Impacto**: Confusión al implementar, tiempo perdido
**Sugerencia**: Actualizar docs para usar `Item` consistentemente
```

#### 2. Código Legacy Problemático
```markdown
⚠️ CÓDIGO LEGACY BLOQUEANTE

**Ubicación**: app/Services/OldInventoryService.php:123
**Problema**: Usa lógica hardcodeada que conflictúa con nueva implementación
**Impacto**: No puedo completar tarea sin refactorizar esto
**Pregunta**: ¿Puedo refactorizar o debo trabajar around?
```

#### 3. Atascado Técnicamente
Si después de 30 minutos sigues atascado:
1. **Resume estado actual**: Qué lograste, dónde estás atascado
2. **Explica el problema**: Error exacto, pasos para reproducir
3. **Muestra lo intentado**: Qué soluciones probaste
4. **Pregunta específica**: Qué necesitas saber para continuar

---

## ✅ CHECKLIST FINAL PRE-ENTREGA

### Código
- [ ] Funciona localmente (probado manualmente con datos reales)
- [ ] Linter OK: `./vendor/bin/pint` sin errores
- [ ] Tests pasan: `php artisan test` sin fallos
- [ ] Migraciones OK: `php artisan migrate:fresh --seed` sin errores
- [ ] Rutas registradas: `php artisan route:list` muestra las nuevas rutas
- [ ] Sin TODOs críticos o FIXMEs bloqueantes

### Base de Datos
- [ ] Migraciones probadas (up y down)
- [ ] Relaciones Eloquent funcionan correctamente
- [ ] Seeders actualizados (permisos, datos de prueba)
- [ ] Índices agregados donde sea necesario

### Frontend
- [ ] Vistas renderizan correctamente
- [ ] Livewire components reactivos (props se actualizan)
- [ ] Assets compilados: `npm run build` sin errores
- [ ] Responsive (probado en mobile/tablet/desktop)

### Seguridad
- [ ] Permisos validados en controllers
- [ ] Inputs sanitizados (FormRequests)
- [ ] No hay datos sensibles en logs o respuestas
- [ ] CSRF protection activo (formularios con @csrf)

### Performance
- [ ] No hay N+1 queries (usar `with()`)
- [ ] Queries <100ms (idealmente)
- [ ] Paginación en listados grandes
- [ ] Caché usado donde aplique

### Documentación
- [ ] PHPDoc completo en métodos públicos
- [ ] README del módulo actualizado
- [ ] API endpoints documentados (si aplica)
- [ ] Variables .env documentadas (si hay nuevas)

---

## 🎉 ENTREGA

### Formato de Entrega

```markdown
## ✅ TAREA COMPLETADA: {NOMBRE_TAREA}

### Resumen
{Breve descripción de lo implementado}

### Archivos Creados
- app/Services/TransferService.php
- app/Http/Controllers/TransferController.php
- resources/views/transfers/index.blade.php
- (etc.)

### Archivos Modificados
- routes/web.php
- database/seeders/PermissionSeeder.php
- (etc.)

### Comandos para Aplicar Cambios
```bash
# Migraciones
php artisan migrate

# Seeders (permisos)
php artisan db:seed --class=PermissionSeeder

# Cache clear
php artisan optimize:clear

# Assets (si aplica)
npm run build
```

### Tests
```bash
# Ejecutar tests del módulo
php artisan test --filter=Transfer

# Resultado: ✅ XX tests passed
```

### Notas Adicionales
- {Cualquier consideración importante}
- {Dependencias o configuraciones necesarias}
- {Próximos pasos sugeridos}

### Checklist Validación
- [x] Linter OK
- [x] Tests pasan
- [x] Migraciones OK
- [x] Funciona manualmente
- [x] Permisos seedeados
- [x] Documentación actualizada
```

### Commits Sugeridos
```bash
# Commit por feature
git add app/Services/TransferService.php app/Models/TransferHeader.php app/Models/TransferDetail.php
git commit -m "feat(transfers): add transfer service and models"

git add app/Http/Controllers/TransferController.php app/Http/Requests/StoreTransferRequest.php
git commit -m "feat(transfers): add transfer controller and validation"

git add resources/views/transfers/ app/Http/Livewire/TransferList.php
git commit -m "feat(transfers): add transfer views and Livewire component"

git add database/migrations/*transfer* database/seeders/PermissionSeeder.php
git commit -m "feat(transfers): add migrations and permissions"

git add tests/Feature/TransferTest.php tests/Unit/TransferServiceTest.php
git commit -m "test(transfers): add transfer tests"

# Push
git push origin {branch}
```

---

## 🔄 PRÓXIMOS PASOS

Después de completar esta tarea:

1. **Notifica al equipo**: Con el formato de entrega (arriba)
2. **Espera validación**: El humano revisará con `CHECKLIST_VALIDACION.md`
3. **Prepárate para ajustes**: Puede haber feedback o mejoras
4. **Pasa a siguiente tarea**: Una vez aprobado, nueva delegación

---

**¡Éxito con la implementación! 🚀**

Si tienes dudas, revisa `docs/UI-UX/MASTER/README.md` o pregunta al humano.

---

**Creado por**: Equipo TerrenaLaravel  
**Versión**: 2.0 (Optimizado)  
**Última actualización**: 2025-10-31  
**Licencia**: Internal Use Only
```

---

## 📌 CHANGELOG

### v2.0 (2025-10-31)
- ✨ Reestructurado para copy-paste directo
- ✨ Variables claramente marcadas con `{MARCADORES}`
- ✨ Ejemplos expandidos y más realistas
- ✨ Checklist de validación más detallado
- ✨ Formato de entrega estandarizado
- ✨ Sección de commits sugeridos
- ✨ Tips de debugging comunes
- ✨ Restricciones y warnings más explícitos

### v1.0 (2025-10-31)
- 🎉 Versión inicial

---

## 🎯 PRÓXIMAS MEJORAS

- [ ] Agregar variantes específicas por tipo de tarea (API-only, Frontend-only, etc.)
- [ ] Templates de tests pre-generados
- [ ] Scripts de validación automatizada
- [ ] Prompts específicos por IA (Claude vs Qwen vs ChatGPT)

---

**¿Preguntas? Revisa `docs/UI-UX/MASTER/README.md` o consulta al equipo.**
