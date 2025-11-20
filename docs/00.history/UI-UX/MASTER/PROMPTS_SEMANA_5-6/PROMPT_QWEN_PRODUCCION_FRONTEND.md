# 🎨 PROMPT QWEN - PRODUCCIÓN: FRONTEND + UI (SEMANA 5)

**Proyecto**: TerrenaLaravel ERP
**Módulo**: Gestión de Producción - Interfaz de Usuario
**Fase**: 2 - Semana 5
**Duración**: 6 horas
**Agent**: Qwen (Frontend Developer)
**Fecha**: Noviembre 29 - Diciembre 5, 2025

---

## 🎯 OBJETIVO

Crear la interfaz de usuario completa para el módulo de Producción con Livewire 3:

1. ✅ 4 Componentes Livewire principales
2. ✅ Vistas Blade responsive
3. ✅ Workflow visual de producción
4. ✅ Validaciones inline y loading states
5. ✅ Toast notifications

**Success Criteria**:
- UI completamente funcional para workflow: Crear → Consumir → Completar → Postear
- Componentes responsive (desktop y mobile)
- Integraci\u00f3n fluida con API backend (semana 4)
- UX intuitiva con feedback visual

---

## 📊 CONTEXTO

### ✅ Backend Ya Implementado (Semana 4)
- **ProductionService** - Lógica completa de producción
- **ProductionController** - 6 endpoints REST funcionando:
  - `GET /api/production/orders` - Lista órdenes
  - `POST /api/production/orders` - Crea orden
  - `GET /api/production/orders/{id}` - Detalle
  - `POST /api/production/orders/{id}/consume` - Consumir ingredientes
  - `POST /api/production/orders/{id}/complete` - Completar orden
  - `POST /api/production/orders/{id}/post` - Postear a inventario
- **ProductionOrder Model** - Con estados y relaciones
- **Database Tables** - `production_orders`, `production_ingredient_consumption`, `production_outputs`

### ⚠️ Falta Implementar (Esta Semana)
- Componentes Livewire para producción
- Vistas Blade responsivas
- Rutas web
- Navegación en sidebar

---

## 📋 PLAN DE TRABAJO (6 HORAS)

### BLOQUE 1: Production Index + Create (2.5h)

#### Tarea 1.1: Componente Production/Index (1h 15min)

**Archivo**: `app/Livewire/Production/Index.php`

**Implementación**:

```php
<?php

namespace App\Livewire\Production;

use Livewire\Component;
use Livewire\WithPagination;
use App\Models\Production\ProductionOrder;
use Illuminate\Support\Facades\Http;

class Index extends Component
{
    use WithPagination;

    public $estado = '';
    public $sucursal_id = '';
    public $fecha_desde = '';
    public $fecha_hasta = '';

    public function mount()
    {
        $this->fecha_desde = now()->subDays(30)->toDateString();
        $this->fecha_hasta = now()->toDateString();
    }

    public function updatingEstado()
    {
        $this->resetPage();
    }

    public function updatingSucursalId()
    {
        $this->resetPage();
    }

    public function clearFilters()
    {
        $this->reset(['estado', 'sucursal_id', 'fecha_desde', 'fecha_hasta']);
        $this->resetPage();
    }

    public function render()
    {
        $query = ProductionOrder::with(['receta', 'almacen', 'sucursal', 'creador']);

        // Aplicar filtros
        if ($this->estado) {
            $query->where('estado', $this->estado);
        }

        if ($this->sucursal_id) {
            $query->where('sucursal_id', $this->sucursal_id);
        }

        if ($this->fecha_desde) {
            $query->whereDate('programado_para', '>=', $this->fecha_desde);
        }

        if ($this->fecha_hasta) {
            $query->whereDate('programado_para', '<=', $this->fecha_hasta);
        }

        $orders = $query->orderByDesc('created_at')->paginate(25);

        return view('livewire.production.index', [
            'orders' => $orders,
        ])->layout('layouts.terrena', ['active' => 'produccion']);
    }
}
```

**Vista**: `resources/views/livewire/production/index.blade.php`

```blade
<div>
    <div class="container-fluid py-4">
        <div class="row mb-3">
            <div class="col-md-6">
                <h2>Órdenes de Producción</h2>
            </div>
            <div class="col-md-6 text-end">
                <a href="{{ route('production.create') }}" class="btn btn-primary">
                    <i class="fas fa-plus"></i> Nueva Orden
                </a>
            </div>
        </div>

        {{-- Filtros --}}
        <div class="card mb-3">
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label">Estado</label>
                        <select wire:model.live="estado" class="form-select">
                            <option value="">Todos</option>
                            <option value="PLANIFICADA">Planificada</option>
                            <option value="APROBADA">Aprobada</option>
                            <option value="EN_PROCESO">En Proceso</option>
                            <option value="COMPLETADA">Completada</option>
                            <option value="POSTEADA">Posteada</option>
                            <option value="CANCELADA">Cancelada</option>
                        </select>
                    </div>

                    <div class="col-md-3">
                        <label class="form-label">Sucursal</label>
                        <select wire:model.live="sucursal_id" class="form-select">
                            <option value="">Todas</option>
                            {{-- TODO: Cargar desde BD --}}
                        </select>
                    </div>

                    <div class="col-md-2">
                        <label class="form-label">Desde</label>
                        <input type="date" wire:model.live="fecha_desde" class="form-control">
                    </div>

                    <div class="col-md-2">
                        <label class="form-label">Hasta</label>
                        <input type="date" wire:model.live="fecha_hasta" class="form-control">
                    </div>

                    <div class="col-md-2 d-flex align-items-end">
                        <button wire:click="clearFilters" class="btn btn-secondary w-100">
                            Limpiar Filtros
                        </button>
                    </div>
                </div>
            </div>
        </div>

        {{-- Tabla de órdenes (Desktop) --}}
        <div class="card d-none d-md-block">
            <div class="card-body">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Receta</th>
                            <th>Cantidad</th>
                            <th>Sucursal</th>
                            <th>Programado</th>
                            <th>Estado</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($orders as $order)
                            <tr>
                                <td>{{ $order->id }}</td>
                                <td>{{ $order->receta->nombre_plato ?? 'N/A' }}</td>
                                <td>
                                    {{ number_format($order->cantidad_planeada, 2) }}
                                    @if($order->cantidad_producida)
                                        <br><small class="text-muted">Producido: {{ number_format($order->cantidad_producida, 2) }}</small>
                                    @endif
                                </td>
                                <td>{{ $order->sucursal->nombre ?? 'N/A' }}</td>
                                <td>{{ $order->programado_para?->format('d/m/Y H:i') }}</td>
                                <td>
                                    @switch($order->estado)
                                        @case('PLANIFICADA')
                                            <span class="badge bg-info">Planificada</span>
                                            @break
                                        @case('APROBADA')
                                            <span class="badge bg-primary">Aprobada</span>
                                            @break
                                        @case('EN_PROCESO')
                                            <span class="badge bg-warning">En Proceso</span>
                                            @break
                                        @case('COMPLETADA')
                                            <span class="badge bg-success">Completada</span>
                                            @break
                                        @case('POSTEADA')
                                            <span class="badge bg-secondary">Posteada</span>
                                            @break
                                        @case('CANCELADA')
                                            <span class="badge bg-danger">Cancelada</span>
                                            @break
                                    @endswitch
                                </td>
                                <td>
                                    <div class="btn-group btn-group-sm">
                                        <a href="{{ route('production.detail', $order->id) }}" class="btn btn-sm btn-outline-primary">
                                            <i class="fas fa-eye"></i>
                                        </a>

                                        @if($order->estado === 'PLANIFICADA' || $order->estado === 'APROBADA')
                                            <a href="{{ route('production.execute', $order->id) }}" class="btn btn-sm btn-outline-success">
                                                <i class="fas fa-play"></i> Ejecutar
                                            </a>
                                        @endif

                                        @if($order->estado === 'COMPLETADA')
                                            <button wire:click="postOrder({{ $order->id }})" class="btn btn-sm btn-outline-success">
                                                <i class="fas fa-check"></i> Postear
                                            </button>
                                        @endif
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="7" class="text-center text-muted py-4">
                                    No hay órdenes de producción
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>

                {{ $orders->links() }}
            </div>
        </div>

        {{-- Cards (Mobile) --}}
        <div class="d-md-none">
            @foreach($orders as $order)
                <div class="card mb-3">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <h5 class="card-title mb-0">{{ $order->receta->nombre_plato ?? 'N/A' }}</h5>
                            @switch($order->estado)
                                @case('PLANIFICADA')
                                    <span class="badge bg-info">Planificada</span>
                                    @break
                                @case('EN_PROCESO')
                                    <span class="badge bg-warning">En Proceso</span>
                                    @break
                                @case('COMPLETADA')
                                    <span class="badge bg-success">Completada</span>
                                    @break
                                @case('POSTEADA')
                                    <span class="badge bg-secondary">Posteada</span>
                                    @break
                            @endswitch
                        </div>

                        <p class="card-text">
                            <small class="text-muted">
                                <strong>Cantidad:</strong> {{ number_format($order->cantidad_planeada, 2) }}<br>
                                <strong>Sucursal:</strong> {{ $order->sucursal->nombre ?? 'N/A' }}<br>
                                <strong>Programado:</strong> {{ $order->programado_para?->format('d/m/Y H:i') }}
                            </small>
                        </p>

                        <div class="d-flex gap-2">
                            <a href="{{ route('production.detail', $order->id) }}" class="btn btn-sm btn-outline-primary flex-fill">
                                Ver Detalle
                            </a>

                            @if($order->estado === 'PLANIFICADA' || $order->estado === 'APROBADA')
                                <a href="{{ route('production.execute', $order->id) }}" class="btn btn-sm btn-outline-success flex-fill">
                                    Ejecutar
                                </a>
                            @endif
                        </div>
                    </div>
                </div>
            @endforeach

            {{ $orders->links() }}
        </div>
    </div>
</div>
```

---

#### Tarea 1.2: Componente Production/Create (1h 15min)

**Archivo**: `app/Livewire/Production/Create.php`

```php
<?php

namespace App\Livewire\Production;

use Livewire\Component;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaVersion;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;

class Create extends Component
{
    public $receta_id = '';
    public $receta_version_id = '';
    public $cantidad_planeada = 1;
    public $almacen_id = '';
    public $sucursal_id = '';
    public $programado_para = '';

    public $recetas = [];
    public $versiones = [];
    public $almacenes = [];
    public $sucursales = [];

    public $loading = false;

    protected $rules = [
        'receta_id' => 'required|string',
        'receta_version_id' => 'required|integer',
        'cantidad_planeada' => 'required|numeric|gt:0',
        'almacen_id' => 'required|integer',
        'sucursal_id' => 'required|integer',
        'programado_para' => 'nullable|date',
    ];

    protected $messages = [
        'receta_id.required' => 'Selecciona una receta',
        'cantidad_planeada.required' => 'Ingresa la cantidad a producir',
        'cantidad_planeada.gt' => 'La cantidad debe ser mayor a 0',
        'almacen_id.required' => 'Selecciona un almacén',
        'sucursal_id.required' => 'Selecciona una sucursal',
    ];

    public function mount()
    {
        $this->recetas = Receta::where('activo', true)
            ->orderBy('nombre_plato')
            ->get(['id', 'nombre_plato']);

        $this->almacenes = DB::connection('pgsql')
            ->table('selemti.cat_almacenes')
            ->where('activo', true)
            ->orderBy('nombre')
            ->get(['id', 'nombre']);

        $this->sucursales = DB::connection('pgsql')
            ->table('selemti.cat_sucursales')
            ->where('activo', true)
            ->orderBy('nombre')
            ->get(['id', 'nombre']);

        $this->programado_para = now()->toDateTimeString();
    }

    public function updatedRecetaId($value)
    {
        if ($value) {
            $this->versiones = RecetaVersion::where('receta_id', $value)
                ->orderByDesc('version')
                ->get(['id', 'version', 'version_publicada']);

            if ($this->versiones->isNotEmpty()) {
                // Seleccionar versión publicada por defecto
                $published = $this->versiones->firstWhere('version_publicada', true);
                $this->receta_version_id = $published ? $published->id : $this->versiones->first()->id;
            }
        } else {
            $this->versiones = [];
            $this->receta_version_id = '';
        }
    }

    public function updated($propertyName)
    {
        $this->validateOnly($propertyName);
    }

    public function save()
    {
        $this->validate();

        $this->loading = true;

        try {
            $response = Http::withToken(session('api_token'))
                ->post(config('app.url') . '/api/production/orders', [
                    'receta_id' => $this->receta_id,
                    'receta_version_id' => $this->receta_version_id,
                    'cantidad_planeada' => $this->cantidad_planeada,
                    'almacen_id' => $this->almacen_id,
                    'sucursal_id' => $this->sucursal_id,
                    'programado_para' => $this->programado_para,
                ]);

            if ($response->successful()) {
                session()->flash('ok', 'Orden de producción creada exitosamente');
                return redirect()->route('production.index');
            } else {
                session()->flash('error', 'Error al crear orden: ' . ($response->json()['message'] ?? 'Error desconocido'));
            }
        } catch (\Exception $e) {
            session()->flash('error', 'Error de conexión: ' . $e->getMessage());
        } finally {
            $this->loading = false;
        }
    }

    public function render()
    {
        return view('livewire.production.create')
            ->layout('layouts.terrena', ['active' => 'produccion']);
    }
}
```

**Vista**: `resources/views/livewire/production/create.blade.php`

```blade
<div>
    <div class="container-fluid py-4">
        <div class="row mb-3">
            <div class="col">
                <h2>Nueva Orden de Producción</h2>
            </div>
        </div>

        <div class="card">
            <div class="card-body">
                <form wire:submit.prevent="save">
                    <div class="row g-3">
                        {{-- Receta --}}
                        <div class="col-md-6">
                            <label class="form-label">Receta <span class="text-danger">*</span></label>
                            <select wire:model.live="receta_id" class="form-select @error('receta_id') is-invalid @enderror">
                                <option value="">Selecciona una receta...</option>
                                @foreach($recetas as $receta)
                                    <option value="{{ $receta->id }}">{{ $receta->nombre_plato }}</option>
                                @endforeach
                            </select>
                            @error('receta_id')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>

                        {{-- Versión --}}
                        <div class="col-md-6">
                            <label class="form-label">Versión</label>
                            <select wire:model="receta_version_id" class="form-select">
                                <option value="">Selecciona una versión...</option>
                                @foreach($versiones as $version)
                                    <option value="{{ $version->id }}">
                                        v{{ $version->version }}
                                        @if($version->version_publicada) (Publicada) @endif
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        {{-- Cantidad --}}
                        <div class="col-md-4">
                            <label class="form-label">Cantidad a Producir <span class="text-danger">*</span></label>
                            <input type="number" wire:model.live="cantidad_planeada" step="0.01" min="0.01" class="form-control @error('cantidad_planeada') is-invalid @enderror">
                            @error('cantidad_planeada')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>

                        {{-- Sucursal --}}
                        <div class="col-md-4">
                            <label class="form-label">Sucursal <span class="text-danger">*</span></label>
                            <select wire:model="sucursal_id" class="form-select @error('sucursal_id') is-invalid @enderror">
                                <option value="">Selecciona...</option>
                                @foreach($sucursales as $sucursal)
                                    <option value="{{ $sucursal->id }}">{{ $sucursal->nombre }}</option>
                                @endforeach
                            </select>
                            @error('sucursal_id')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>

                        {{-- Almacén --}}
                        <div class="col-md-4">
                            <label class="form-label">Almacén Destino <span class="text-danger">*</span></label>
                            <select wire:model="almacen_id" class="form-select @error('almacen_id') is-invalid @enderror">
                                <option value="">Selecciona...</option>
                                @foreach($almacenes as $almacen)
                                    <option value="{{ $almacen->id }}">{{ $almacen->nombre }}</option>
                                @endforeach
                            </select>
                            @error('almacen_id')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>

                        {{-- Fecha programada --}}
                        <div class="col-md-6">
                            <label class="form-label">Programado Para</label>
                            <input type="datetime-local" wire:model="programado_para" class="form-control">
                        </div>
                    </div>

                    <div class="row mt-4">
                        <div class="col">
                            <button type="submit" class="btn btn-primary" @if($loading) disabled @endif>
                                @if($loading)
                                    <span class="spinner-border spinner-border-sm me-2"></span>
                                @endif
                                Crear Orden de Producción
                            </button>

                            <a href="{{ route('production.index') }}" class="btn btn-secondary">
                                Cancelar
                            </a>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
```

---

### BLOQUE 2: Production Execute + Detail (2h)

#### Tarea 2.1: Componente Production/Execute (1h 15min)

**Archivo**: `app/Livewire/Production/Execute.php`

*(Componente complejo con 3 pasos: Consumir → Producir → Completar)*

**Vista**: `resources/views/livewire/production/execute.blade.php`

*(Wizard de 3 pasos con tabs o stepper)*

---

#### Tarea 2.2: Componente Production/Detail (45min)

**Archivo**: `app/Livewire/Production/Detail.php`

**Vista**: `resources/views/livewire/production/detail.blade.php`

*(Vista de solo lectura con información completa de la orden)*

---

### BLOQUE 3: Rutas y Navegación (30min + 1h)

#### Tarea 3.1: Registrar Rutas Web (15min)

**Archivo**: `routes/web.php`

```php
Route::middleware(['auth'])->prefix('production')->name('production.')->group(function () {
    Route::get('/', \App\Livewire\Production\Index::class)->name('index');
    Route::get('/create', \App\Livewire\Production\Create::class)->name('create');
    Route::get('/{id}/detail', \App\Livewire\Production\Detail::class)->name('detail');
    Route::get('/{id}/execute', \App\Livewire\Production\Execute::class)->name('execute');
});
```

---

## ✅ CHECKLIST DE VALIDACIÓN

### Componentes Livewire
- [ ] Production/Index completo con filtros
- [ ] Production/Create con validaciones inline
- [ ] Production/Execute con wizard de 3 pasos
- [ ] Production/Detail con información completa
- [ ] Loading states en todos los componentes
- [ ] Toast notifications configuradas

### UI/UX
- [ ] Responsive (desktop y mobile)
- [ ] Badges de estado con colores correctos
- [ ] Formularios con validación inline
- [ ] Spinners durante llamadas API
- [ ] Cards para mobile

### Integración
- [ ] Llamadas a API funcionando
- [ ] Autenticación con token configurada
- [ ] Manejo de errores correcto
- [ ] Redirecciones apropiadas

---

**Versión**: 1.0
**Fecha**: 31 de Octubre 2025

🎨 **¡UI de Producción lista para implementar!**
