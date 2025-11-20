# 🎨 PROMPT QWEN - TRANSFERENCIAS FRONTEND + UI (SEMANA 2)

**Proyecto**: TerrenaLaravel ERP
**Módulo**: Transferencias entre Almacenes
**Fase**: 1 - Semana 2
**Duración**: 6 horas
**Agent**: Qwen (Frontend Developer)
**Fecha**: Noviembre 8-14, 2025

---

## 🎯 OBJETIVO

Completar la interfaz de usuario del módulo de Transferencias entre almacenes:

1. ✅ 4 Componentes Livewire (Index, Create, Dispatch, Receive)
2. ✅ Vistas Blade responsive y mobile-friendly
3. ✅ Wizard de 3 pasos para crear transferencias
4. ✅ Validaciones inline con mensajes claros
5. ✅ Loading states y toast notifications

**Success Criteria**:
- UI completamente funcional
- Workflow completo: Crear → Aprobar → Despachar → Recibir
- Mobile-optimized (responsive)
- UX fluida con feedback visual

---

## 📊 ESTADO ACTUAL

### ✅ Backend Ya Implementado (Semana 1)
- API endpoints completos (`/api/inventory/transfers/*`)
- TransferService con lógica completa
- Modelos TransferHeader y TransferLine
- Tests passing 100%

### ⚠️ Frontend Parcialmente Implementado
- `app/Livewire/Transfers/Create.php` - Básico, necesita wizard
- `app/Livewire/Transfers/Index.php` - Básico, necesita acciones
- Vistas Blade - Necesitan mejora UX

### ❌ Falta Implementar
- Componente Dispatch (despacho/envío)
- Componente Receive (recepción)
- Wizard de 3 pasos en Create
- Validaciones inline
- Loading states y spinners
- Toast notifications
- Modal de confirmación para aprobar/despachar/recibir

---

## 📋 PLAN DE TRABAJO (6 HORAS)

### BLOQUE 1: Index + Acciones (2h)

#### Tarea 1.1: Mejorar Transfers/Index (1h)

**Archivo**: `app/Livewire/Transfers/Index.php`

Implementar:
- Filtros por estado, almacén origen/destino, fecha
- Tabla con badges de estado (colores según estado)
- Acciones contextuales por estado:
  - SOLICITADA: Aprobar / Editar / Cancelar
  - APROBADA: Despachar
  - EN_TRANSITO: Recibir
  - RECIBIDA: Postear
- Paginación con Livewire
- Loading states en botones

**Vista**: `resources/views/livewire/transfers/index.blade.php`

Implementar:
- Tabla responsive con cards en mobile
- Badges de estado con colores Bootstrap 5
- Dropdowns de acciones con iconos
- Skeleton loaders

#### Tarea 1.2: Modal de Aprobación (1h)

Agregar modal de confirmación para aprobar transferencias con:
- Resumen de ítems
- Validación de stock (mostrar warning si es insuficiente)
- Botón "Aprobar" con loading spinner
- Toast success/error

---

### BLOQUE 2: Wizard de Creación (2h)

#### Tarea 2.1: Wizard de 3 Pasos (1h 30min)

**Componente**: `app/Livewire/Transfers/Create.php`

Paso 1: Información General
- Almacén origen (select)
- Almacén destino (select)
- Fecha solicitada (date picker)
- Observaciones (textarea)

Paso 2: Agregar Ítems
- Tabla dinámica con add/remove rows
- Select de ítems con búsqueda
- Input cantidad con validación >0
- Select UOM (unidad de medida)
- Botón "Agregar línea"

Paso 3: Revisión y Confirmación
- Resumen de transferencia
- Tabla de ítems agregados
- Totales (cantidad de ítems, cantidad total)
- Botón "Crear Transferencia"

**Características**:
- Progress bar (Paso 1/3, 2/3, 3/3)
- Validación por paso (no avanza si falta data)
- Botones "Anterior" / "Siguiente" / "Finalizar"
- Loading spinner en "Finalizar"
- Toast success y redirect a Index

#### Tarea 2.2: Validaciones Inline (30min)

Agregar:
- `wire:model.live` en todos los inputs
- `updated($propertyName)` + `validateOnly()`
- `@error` debajo de cada campo
- Mensajes custom en español

---

### BLOQUE 3: Dispatch + Receive (2h)

#### Tarea 3.1: Componente Dispatch (45min)

**Archivo**: `app/Livewire/Transfers/Dispatch.php`

Mostrar:
- Info de transferencia (origen, destino, fecha)
- Tabla de ítems con cantidad solicitada
- Input "Número de guía" (opcional)
- Input "Cantidad despachada" por ítem (editable, default = solicitada)
- Botón "Marcar en Tránsito"

Llamar:
- `POST /api/inventory/transfers/{id}/ship`

#### Tarea 3.2: Componente Receive (1h)

**Archivo**: `app/Livewire/Transfers/Receive.php`

Mostrar:
- Info de transferencia (origen, destino, guía, fecha despachada)
- Tabla comparativa:
  - Cantidad despachada
  - Cantidad recibida (input editable)
  - Diferencia (calculada automáticamente)
  - Varianza % (calculada)
  - Observaciones por línea (textarea)
- Resumen de diferencias totales
- Botón "Registrar Recepción"

Llamar:
- `POST /api/inventory/transfers/{id}/receive`

Características:
- Highlight diferencias >5% en amarillo
- Highlight diferencias >10% en rojo
- Alerta si diferencia es muy alta
- Modal de confirmación antes de guardar

#### Tarea 3.3: Componente Post (15min)

Botón simple "Postear a Inventario" con:
- Confirmación modal
- Loading spinner
- Toast success
- Llamar `POST /api/inventory/transfers/{id}/post`

---

## ✅ CHECKLIST DE VALIDACIÓN

### UI/UX
- [ ] Index con filtros funcionales
- [ ] Badges de estado con colores correctos
- [ ] Acciones contextuales por estado
- [ ] Wizard de 3 pasos fluido
- [ ] Validaciones inline en tiempo real
- [ ] Loading states en todos los botones
- [ ] Toast notifications en todas las acciones

### Responsive
- [ ] Tablas se vuelven cards en mobile
- [ ] Wizard responsive
- [ ] Modales full-screen en mobile
- [ ] Touch targets >44px

### Funcionalidad
- [ ] Crear transferencia end-to-end
- [ ] Aprobar transferencia
- [ ] Despachar transferencia
- [ ] Recibir transferencia
- [ ] Postear a inventario
- [ ] Filtros funcionando
- [ ] Paginación funcionando

---

## 📦 ENTREGABLES

1. **Componentes Livewire**
   - `app/Livewire/Transfers/Index.php` (mejorado)
   - `app/Livewire/Transfers/Create.php` (wizard)
   - `app/Livewire/Transfers/Dispatch.php` (nuevo)
   - `app/Livewire/Transfers/Receive.php` (nuevo)

2. **Vistas Blade**
   - `resources/views/livewire/transfers/index.blade.php`
   - `resources/views/livewire/transfers/create.blade.php`
   - `resources/views/livewire/transfers/dispatch.blade.php`
   - `resources/views/livewire/transfers/receive.blade.php`

3. **Componentes Reutilizables**
   - `resources/views/components/transfer-status-badge.blade.php`
   - `resources/views/components/progress-stepper.blade.php`

4. **Rutas**
   - Actualizar `routes/web.php` con nuevas rutas

---

## 🎨 EJEMPLOS DE UI

### Estado Badges

```html
@switch($transfer->estado)
    @case('SOLICITADA')
        <span class="badge bg-info">Solicitada</span>
    @case('APROBADA')
        <span class="badge bg-primary">Aprobada</span>
    @case('EN_TRANSITO')
        <span class="badge bg-warning">En Tránsito</span>
    @case('RECIBIDA')
        <span class="badge bg-success">Recibida</span>
    @case('POSTEADA')
        <span class="badge bg-secondary">Posteada</span>
@endswitch
```

### Progress Stepper

```html
<div class="progress-stepper mb-4">
    <div class="step {{ $currentStep >= 1 ? 'active' : '' }}">
        <div class="step-number">1</div>
        <div class="step-title">Información</div>
    </div>
    <div class="step {{ $currentStep >= 2 ? 'active' : '' }}">
        <div class="step-number">2</div>
        <div class="step-title">Ítems</div>
    </div>
    <div class="step {{ $currentStep >= 3 ? 'active' : '' }}">
        <div class="step-number">3</div>
        <div class="step-title">Confirmar</div>
    </div>
</div>
```

### Tabla Comparativa (Receive)

```html
<table class="table">
    <thead>
        <tr>
            <th>Ítem</th>
            <th>Despachado</th>
            <th>Recibido</th>
            <th>Diferencia</th>
            <th>Varianza</th>
        </tr>
    </thead>
    <tbody>
        @foreach($lineas as $index => $linea)
        <tr class="{{ abs($linea->varianza_porcentaje) > 10 ? 'table-danger' : (abs($linea->varianza_porcentaje) > 5 ? 'table-warning' : '') }}">
            <td>{{ $linea->item->nombre }}</td>
            <td>{{ number_format($linea->cantidad_despachada, 2) }}</td>
            <td>
                <input type="number" wire:model.live="lineas.{{ $index }}.cantidad_recibida" step="0.01" min="0" class="form-control form-control-sm">
            </td>
            <td>{{ number_format($linea->diferencia, 2) }}</td>
            <td>
                @if($linea->varianza_porcentaje !== null)
                    {{ number_format($linea->varianza_porcentaje, 1) }}%
                @endif
            </td>
        </tr>
        @endforeach
    </tbody>
</table>
```

---

## 🚀 COMANDOS ÚTILES

```bash
# Crear componentes
php artisan make:livewire Transfers/Dispatch
php artisan make:livewire Transfers/Receive

# Ver rutas
php artisan route:list --path=transfers

# Limpiar cache
php artisan view:clear
php artisan livewire:publish --force
```

---

## 🔒 VALIDACIONES COMPLETAS DEL FRONTEND

### 1. VALIDACIONES DE FORMULARIOS (Form Validation)

#### 1.1 Validaciones en Create.php - Paso 1 (Información General)

**Reglas de validación**:
```php
class Create extends Component
{
    public $currentStep = 1;
    public $origen_almacen_id;
    public $destino_almacen_id;
    public $fecha_solicitada;
    public $observaciones;

    protected function rules()
    {
        return [
            'origen_almacen_id' => [
                'required',
                'integer',
                'exists:selemti.cat_almacenes,id',
                'different:destino_almacen_id',
            ],
            'destino_almacen_id' => [
                'required',
                'integer',
                'exists:selemti.cat_almacenes,id',
            ],
            'fecha_solicitada' => [
                'nullable',
                'date',
                'after_or_equal:today',
            ],
            'observaciones' => [
                'nullable',
                'string',
                'max:1000',
            ],
        ];
    }

    protected $messages = [
        'origen_almacen_id.required' => 'Debe seleccionar un almacén de origen',
        'origen_almacen_id.different' => 'El almacén origen debe ser diferente al destino',
        'destino_almacen_id.required' => 'Debe seleccionar un almacén de destino',
        'fecha_solicitada.after_or_equal' => 'La fecha no puede ser anterior a hoy',
        'observaciones.max' => 'Las observaciones no pueden exceder 1000 caracteres',
    ];

    // Validación en tiempo real
    public function updated($propertyName)
    {
        $this->validateOnly($propertyName);
    }

    // Validación antes de avanzar de paso
    public function nextStep()
    {
        if ($this->currentStep === 1) {
            $this->validate([
                'origen_almacen_id' => 'required|integer|different:destino_almacen_id',
                'destino_almacen_id' => 'required|integer',
            ]);
        }

        $this->currentStep++;
    }
}
```

**Vista Blade con validaciones inline**:
```html
<div class="mb-3">
    <label class="form-label">Almacén Origen <span class="text-danger">*</span></label>
    <select
        wire:model.live="origen_almacen_id"
        class="form-select @error('origen_almacen_id') is-invalid @enderror"
        required
    >
        <option value="">Seleccione...</option>
        @foreach($almacenes as $almacen)
            <option value="{{ $almacen->id }}">{{ $almacen->nombre }}</option>
        @endforeach
    </select>
    @error('origen_almacen_id')
        <div class="invalid-feedback">{{ $message }}</div>
    @enderror
</div>

<div class="mb-3">
    <label class="form-label">Almacén Destino <span class="text-danger">*</span></label>
    <select
        wire:model.live="destino_almacen_id"
        class="form-select @error('destino_almacen_id') is-invalid @enderror"
        required
    >
        <option value="">Seleccione...</option>
        @foreach($almacenes as $almacen)
            <option value="{{ $almacen->id }}"
                {{ $almacen->id == $origen_almacen_id ? 'disabled' : '' }}>
                {{ $almacen->nombre }}
            </option>
        @endforeach
    </select>
    @error('destino_almacen_id')
        <div class="invalid-feedback">{{ $message }}</div>
    @enderror
</div>
```

#### 1.2 Validaciones en Create.php - Paso 2 (Ítems)

**Reglas de validación**:
```php
public $lineas = [];
protected $validationAttributes = [
    'lineas.*.item_id' => 'ítem',
    'lineas.*.cantidad' => 'cantidad',
    'lineas.*.uom_id' => 'unidad de medida',
];

protected function rulesForLineas()
{
    return [
        'lineas' => 'required|array|min:1|max:100',
        'lineas.*.item_id' => 'required|string|exists:selemti.items,id',
        'lineas.*.cantidad' => 'required|numeric|min:0.001|max:999999.999',
        'lineas.*.uom_id' => 'required|integer|exists:selemti.cat_unidades,id',
    ];
}

protected $messages = [
    'lineas.required' => 'Debe agregar al menos un ítem',
    'lineas.min' => 'Debe agregar al menos un ítem',
    'lineas.max' => 'No puede agregar más de 100 ítems',
    'lineas.*.item_id.required' => 'El ítem es obligatorio',
    'lineas.*.cantidad.required' => 'La cantidad es obligatoria',
    'lineas.*.cantidad.min' => 'La cantidad debe ser mayor a 0',
    'lineas.*.cantidad.max' => 'La cantidad no puede exceder 999,999.999',
    'lineas.*.uom_id.required' => 'La unidad de medida es obligatoria',
];

public function addLinea()
{
    // Validar que no haya más de 100 líneas
    if (count($this->lineas) >= 100) {
        $this->addError('lineas', 'No puede agregar más de 100 ítems');
        return;
    }

    $this->lineas[] = [
        'item_id' => '',
        'cantidad' => '',
        'uom_id' => '',
    ];
}

public function removeLinea($index)
{
    unset($this->lineas[$index]);
    $this->lineas = array_values($this->lineas);

    // Validar que quede al menos una línea
    if (count($this->lineas) === 0) {
        $this->addError('lineas', 'Debe mantener al menos un ítem');
    }
}

// Validación antes de avanzar al paso 3
public function nextStep()
{
    if ($this->currentStep === 2) {
        $this->validate($this->rulesForLineas());

        // Validación adicional: verificar ítems duplicados
        $itemIds = collect($this->lineas)->pluck('item_id')->filter();
        if ($itemIds->count() !== $itemIds->unique()->count()) {
            $this->addError('lineas', 'No puede agregar el mismo ítem más de una vez');
            return;
        }
    }

    $this->currentStep++;
}
```

**Vista Blade con validaciones inline**:
```html
<div class="table-responsive">
    <table class="table">
        <thead>
            <tr>
                <th>Ítem</th>
                <th>Cantidad</th>
                <th>UOM</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
            @foreach($lineas as $index => $linea)
            <tr>
                <td>
                    <select
                        wire:model.live="lineas.{{ $index }}.item_id"
                        class="form-select @error("lineas.{$index}.item_id") is-invalid @enderror"
                        required
                    >
                        <option value="">Seleccione...</option>
                        @foreach($items as $item)
                            <option value="{{ $item->id }}">{{ $item->nombre }}</option>
                        @endforeach
                    </select>
                    @error("lineas.{$index}.item_id")
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </td>
                <td>
                    <input
                        type="number"
                        wire:model.live="lineas.{{ $index }}.cantidad"
                        class="form-control @error("lineas.{$index}.cantidad") is-invalid @enderror"
                        step="0.001"
                        min="0.001"
                        max="999999.999"
                        required
                    >
                    @error("lineas.{$index}.cantidad")
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </td>
                <td>
                    <select
                        wire:model.live="lineas.{{ $index }}.uom_id"
                        class="form-select @error("lineas.{$index}.uom_id") is-invalid @enderror"
                        required
                    >
                        <option value="">UOM...</option>
                        @foreach($uoms as $uom)
                            <option value="{{ $uom->id }}">{{ $uom->clave }}</option>
                        @endforeach
                    </select>
                    @error("lineas.{$index}.uom_id")
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </td>
                <td>
                    <button
                        type="button"
                        wire:click="removeLinea({{ $index }})"
                        class="btn btn-sm btn-danger"
                        {{ count($lineas) === 1 ? 'disabled' : '' }}
                    >
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            </tr>
            @endforeach
        </tbody>
    </table>
</div>

@error('lineas')
    <div class="alert alert-danger">{{ $message }}</div>
@enderror

<button
    type="button"
    wire:click="addLinea"
    class="btn btn-secondary"
    {{ count($lineas) >= 100 ? 'disabled' : '' }}
>
    <i class="bi bi-plus-circle"></i> Agregar Ítem
</button>
```

#### 1.3 Validaciones en Receive.php (Recepción)

**Reglas de validación**:
```php
public $lineas = [];
protected $rules = [
    'lineas.*.cantidad_recibida' => 'required|numeric|min:0|max:999999.999',
    'lineas.*.observaciones' => 'nullable|string|max:500',
];

protected $messages = [
    'lineas.*.cantidad_recibida.required' => 'La cantidad recibida es obligatoria',
    'lineas.*.cantidad_recibida.min' => 'La cantidad no puede ser negativa',
    'lineas.*.cantidad_recibida.max' => 'La cantidad excede el límite permitido',
    'lineas.*.observaciones.max' => 'Las observaciones no pueden exceder 500 caracteres',
];

public function updated($propertyName)
{
    $this->validateOnly($propertyName);

    // Calcular varianza en tiempo real
    if (str_contains($propertyName, 'cantidad_recibida')) {
        $index = explode('.', $propertyName)[1];
        $this->calcularVarianza($index);
    }
}

private function calcularVarianza($index)
{
    $linea = &$this->lineas[$index];
    $despachada = floatval($linea['cantidad_despachada']);
    $recibida = floatval($linea['cantidad_recibida']);

    if ($despachada > 0) {
        $linea['diferencia'] = $recibida - $despachada;
        $linea['varianza_porcentaje'] = (($recibida - $despachada) / $despachada) * 100;

        // Validación de tolerancia
        if (abs($linea['varianza_porcentaje']) > 10) {
            $this->addError(
                "lineas.{$index}.cantidad_recibida",
                "Varianza muy alta ({$linea['varianza_porcentaje']}%). Verifique la cantidad."
            );
        }
    }
}

public function registrarRecepcion()
{
    $this->validate();

    // Validación adicional: al menos una línea debe tener cantidad > 0
    $totalRecibido = collect($this->lineas)->sum('cantidad_recibida');
    if ($totalRecibido <= 0) {
        $this->addError('lineas', 'Debe recibir al menos un ítem');
        return;
    }

    // Continuar con el registro...
}
```

### 2. VALIDACIONES DE NEGOCIO (Business Logic)

#### 2.1 Validación de Estados para Acciones

**En Index.php**:
```php
public function aprobar($transferId)
{
    $transfer = TransferHeader::findOrFail($transferId);

    // Validar estado
    if ($transfer->estado !== 'SOLICITADA') {
        $this->dispatch('error', message: 'Solo se pueden aprobar transferencias solicitadas');
        return;
    }

    // Validar permisos
    if (!auth()->user()->can('inventory.transfers.approve')) {
        $this->dispatch('error', message: 'No tiene permisos para aprobar transferencias');
        return;
    }

    try {
        // Llamar API
        $response = Http::post("/api/inventory/transfers/{$transferId}/approve");

        if ($response->successful()) {
            $this->dispatch('success', message: 'Transferencia aprobada exitosamente');
            $this->dispatch('refresh');
        } else {
            $this->dispatch('error', message: $response->json('message'));
        }
    } catch (\Exception $e) {
        $this->dispatch('error', message: 'Error al aprobar transferencia');
    }
}

// Métodos helper para validar acciones permitidas
public function puedeAprobar($transfer): bool
{
    return $transfer->estado === 'SOLICITADA'
        && auth()->user()->can('inventory.transfers.approve');
}

public function puedeDespachar($transfer): bool
{
    return $transfer->estado === 'APROBADA'
        && auth()->user()->can('inventory.transfers.ship');
}

public function puedeRecibir($transfer): bool
{
    return $transfer->estado === 'EN_TRANSITO'
        && auth()->user()->can('inventory.transfers.receive');
}

public function puedePostear($transfer): bool
{
    return $transfer->estado === 'RECIBIDA'
        && auth()->user()->can('inventory.transfers.post');
}
```

**En Vista Blade**:
```html
@if($this->puedeAprobar($transfer))
    <button
        wire:click="aprobar({{ $transfer->id }})"
        class="btn btn-sm btn-primary"
        wire:loading.attr="disabled"
    >
        <span wire:loading.remove wire:target="aprobar">Aprobar</span>
        <span wire:loading wire:target="aprobar">
            <span class="spinner-border spinner-border-sm"></span> Aprobando...
        </span>
    </button>
@endif

@if($this->puedeDespachar($transfer))
    <a
        href="{{ route('transfers.dispatch', $transfer->id) }}"
        class="btn btn-sm btn-warning"
    >
        Despachar
    </a>
@endif
```

### 3. VALIDACIONES DE UX (User Experience)

#### 3.1 Confirmaciones Modales

**Antes de acciones críticas**:
```php
public $showApproveModal = false;
public $transferToApprove = null;

public function confirmApprove($transferId)
{
    $this->transferToApprove = TransferHeader::with('lineas.item')->findOrFail($transferId);
    $this->showApproveModal = true;
}

public function aprobar()
{
    if (!$this->transferToApprove) {
        return;
    }

    // Validar estado nuevamente antes de aprobar
    if ($this->transferToApprove->estado !== 'SOLICITADA') {
        $this->dispatch('error', message: 'El estado de la transferencia cambió');
        $this->showApproveModal = false;
        return;
    }

    // Continuar con aprobación...
    $this->showApproveModal = false;
}
```

**Vista Modal**:
```html
@if($showApproveModal)
<div class="modal show d-block" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Confirmar Aprobación</h5>
                <button type="button" class="btn-close" wire:click="$set('showApproveModal', false)"></button>
            </div>
            <div class="modal-body">
                <p>¿Está seguro de aprobar esta transferencia?</p>

                <div class="table-responsive">
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th>Ítem</th>
                                <th>Cantidad</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($transferToApprove->lineas as $linea)
                            <tr>
                                <td>{{ $linea->item->nombre }}</td>
                                <td>{{ number_format($linea->cantidad_solicitada, 2) }}</td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>

                <div class="alert alert-warning">
                    <i class="bi bi-exclamation-triangle"></i>
                    Esta acción validará el stock disponible en el almacén origen.
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" wire:click="$set('showApproveModal', false)">
                    Cancelar
                </button>
                <button type="button" class="btn btn-primary" wire:click="aprobar" wire:loading.attr="disabled">
                    <span wire:loading.remove wire:target="aprobar">Confirmar</span>
                    <span wire:loading wire:target="aprobar">
                        <span class="spinner-border spinner-border-sm"></span> Aprobando...
                    </span>
                </button>
            </div>
        </div>
    </div>
</div>
<div class="modal-backdrop show"></div>
@endif
```

#### 3.2 Toast Notifications

**Implementación en componente**:
```php
protected $listeners = ['success', 'error', 'warning'];

public function success($message)
{
    $this->dispatch('toast', [
        'type' => 'success',
        'message' => $message,
    ]);
}

public function error($message)
{
    $this->dispatch('toast', [
        'type' => 'error',
        'message' => $message,
    ]);
}
```

**Componente Toast en Layout**:
```html
<!-- resources/views/components/toast.blade.php -->
<div
    x-data="{ show: false, message: '', type: 'info' }"
    @toast.window="
        show = true;
        message = $event.detail.message;
        type = $event.detail.type;
        setTimeout(() => show = false, 3000)
    "
    x-show="show"
    x-transition
    class="position-fixed top-0 end-0 p-3"
    style="z-index: 9999"
>
    <div
        class="toast show"
        :class="{
            'bg-success text-white': type === 'success',
            'bg-danger text-white': type === 'error',
            'bg-warning': type === 'warning',
        }"
    >
        <div class="toast-body">
            <i class="bi" :class="{
                'bi-check-circle': type === 'success',
                'bi-x-circle': type === 'error',
                'bi-exclamation-triangle': type === 'warning',
            }"></i>
            <span x-text="message"></span>
        </div>
    </div>
</div>
```

### 4. VALIDACIONES DE RESPONSIVE (Mobile-First)

#### 4.1 Validación de Tamaño de Pantalla

**Tablas responsivas**:
```html
<!-- Desktop: tabla normal -->
<div class="d-none d-md-block">
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>Origen</th>
                <th>Destino</th>
                <th>Estado</th>
                <th>Fecha</th>
                <th>Acciones</th>
            </tr>
        </thead>
        <tbody>
            @foreach($transfers as $transfer)
            <tr>
                <td>{{ $transfer->id }}</td>
                <td>{{ $transfer->origenAlmacen->nombre }}</td>
                <td>{{ $transfer->destinoAlmacen->nombre }}</td>
                <td><x-transfer-status-badge :status="$transfer->estado" /></td>
                <td>{{ $transfer->fecha_solicitada?->format('d/m/Y') }}</td>
                <td>
                    <!-- Acciones -->
                </td>
            </tr>
            @endforeach
        </tbody>
    </table>
</div>

<!-- Mobile: cards -->
<div class="d-block d-md-none">
    @foreach($transfers as $transfer)
    <div class="card mb-3">
        <div class="card-body">
            <div class="d-flex justify-content-between align-items-start mb-2">
                <h6 class="card-title mb-0">Transfer #{{ $transfer->id }}</h6>
                <x-transfer-status-badge :status="$transfer->estado" />
            </div>
            <p class="card-text small mb-1">
                <strong>Origen:</strong> {{ $transfer->origenAlmacen->nombre }}<br>
                <strong>Destino:</strong> {{ $transfer->destinoAlmacen->nombre }}<br>
                <strong>Fecha:</strong> {{ $transfer->fecha_solicitada?->format('d/m/Y') }}
            </p>
            <div class="btn-group btn-group-sm w-100" role="group">
                <!-- Acciones responsive -->
            </div>
        </div>
    </div>
    @endforeach
</div>
```

#### 4.2 Touch Targets

**Validación de tamaño mínimo 44x44px**:
```css
/* resources/css/app.css */
@media (max-width: 767px) {
    .btn-sm {
        min-height: 44px;
        min-width: 44px;
    }

    .form-control,
    .form-select {
        min-height: 44px;
    }

    /* Aumentar área clickable en mobile */
    .table tbody tr {
        cursor: pointer;
    }

    .table tbody td {
        padding: 1rem;
    }
}
```

### 5. VALIDACIONES DE SEGURIDAD (Frontend Security)

#### 5.1 CSRF Protection

**Verificar que todos los formularios incluyan @csrf**:
```html
<form wire:submit="save">
    @csrf
    <!-- campos del formulario -->
</form>
```

#### 5.2 XSS Prevention

**Escapar datos del usuario**:
```html
<!-- ✅ CORRECTO - Blade escapa automáticamente -->
<p>{{ $transfer->observaciones }}</p>

<!-- ❌ INCORRECTO - No usar {!! !!} con input del usuario -->
<p>{!! $transfer->observaciones !!}</p>

<!-- ✅ CORRECTO - Si necesitas HTML, sanitiza primero -->
<p>{!! strip_tags($transfer->observaciones, '<br><b><i>') !!}</p>
```

#### 5.3 Validación de Autorización

**Ocultar acciones no permitidas**:
```html
@can('inventory.transfers.approve')
    <button wire:click="aprobar({{ $transfer->id }})" class="btn btn-sm btn-primary">
        Aprobar
    </button>
@endcan

@can('inventory.transfers.ship')
    <a href="{{ route('transfers.dispatch', $transfer->id) }}" class="btn btn-sm btn-warning">
        Despachar
    </a>
@endcan
```

### 6. VALIDACIONES DE ACCESIBILIDAD (A11y)

#### 6.1 ARIA Labels y Roles

**Etiquetas descriptivas**:
```html
<button
    wire:click="removeLinea({{ $index }})"
    class="btn btn-sm btn-danger"
    aria-label="Eliminar ítem {{ $linea['item_id'] }}"
    {{ count($lineas) === 1 ? 'disabled' : '' }}
>
    <i class="bi bi-trash" aria-hidden="true"></i>
</button>

<div role="status" aria-live="polite" wire:loading wire:target="save">
    Guardando transferencia...
</div>
```

#### 6.2 Navegación por Teclado

**Tab order y focus management**:
```html
<div class="modal" tabindex="-1" role="dialog" aria-labelledby="modalTitle">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="modalTitle">Confirmar Aprobación</h5>
                <button
                    type="button"
                    class="btn-close"
                    wire:click="$set('showApproveModal', false)"
                    aria-label="Cerrar"
                ></button>
            </div>
            <!-- contenido -->
        </div>
    </div>
</div>
```

#### 6.3 Mensajes de Error Accesibles

**Asociar errores con inputs**:
```html
<div class="mb-3">
    <label for="cantidad-{{ $index }}" class="form-label">Cantidad</label>
    <input
        type="number"
        id="cantidad-{{ $index }}"
        wire:model.live="lineas.{{ $index }}.cantidad"
        class="form-control @error("lineas.{$index}.cantidad") is-invalid @enderror"
        aria-describedby="cantidad-{{ $index }}-error"
        aria-invalid="@error("lineas.{$index}.cantidad")true@enderror"
    >
    @error("lineas.{$index}.cantidad")
        <div id="cantidad-{{ $index }}-error" class="invalid-feedback" role="alert">
            {{ $message }}
        </div>
    @enderror
</div>
```

### 7. VALIDACIONES DE LOADING STATES

#### 7.1 Loading Spinners

**En todos los botones de acción**:
```html
<button
    type="button"
    wire:click="save"
    class="btn btn-primary"
    wire:loading.attr="disabled"
    wire:target="save"
>
    <span wire:loading.remove wire:target="save">
        Guardar Transferencia
    </span>
    <span wire:loading wire:target="save">
        <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
        Guardando...
    </span>
</button>
```

#### 7.2 Skeleton Loaders

**Durante carga inicial**:
```html
<div wire:loading.delay wire:target="loadTransfers">
    <div class="card mb-3">
        <div class="card-body">
            <div class="placeholder-glow">
                <span class="placeholder col-6"></span>
                <span class="placeholder col-8"></span>
                <span class="placeholder col-4"></span>
            </div>
        </div>
    </div>
</div>

<div wire:loading.remove wire:target="loadTransfers">
    <!-- Contenido real -->
</div>
```

### 8. VALIDACIONES DE FILTROS (Index)

#### 8.1 Validación de Filtros

```php
public $filtroEstado = '';
public $filtroOrigen = '';
public $filtroDestino = '';
public $filtroFechaDesde = '';
public $filtroFechaHasta = '';

protected $rules = [
    'filtroEstado' => 'nullable|string|in:SOLICITADA,APROBADA,EN_TRANSITO,RECIBIDA,POSTEADA',
    'filtroOrigen' => 'nullable|integer|exists:selemti.cat_almacenes,id',
    'filtroDestino' => 'nullable|integer|exists:selemti.cat_almacenes,id',
    'filtroFechaDesde' => 'nullable|date',
    'filtroFechaHasta' => 'nullable|date|after_or_equal:filtroFechaDesde',
];

protected $messages = [
    'filtroFechaHasta.after_or_equal' => 'La fecha hasta debe ser posterior a la fecha desde',
];

public function updated($propertyName)
{
    // Validar solo filtros
    if (str_starts_with($propertyName, 'filtro')) {
        $this->validateOnly($propertyName);
        $this->resetPage(); // Reset pagination al cambiar filtros
    }
}

public function limpiarFiltros()
{
    $this->reset(['filtroEstado', 'filtroOrigen', 'filtroDestino', 'filtroFechaDesde', 'filtroFechaHasta']);
    $this->resetPage();
}
```

### 9. CHECKLIST DE VALIDACIONES FRONTEND

Al implementar, verificar que TODAS estas validaciones estén presentes:

**Formularios**:
- [ ] Validación en tiempo real (wire:model.live)
- [ ] Mensajes de error en español
- [ ] Validación antes de avanzar de paso (wizard)
- [ ] Validación de campos requeridos
- [ ] Validación de rangos y formatos
- [ ] Feedback visual (is-invalid class)

**Negocio**:
- [ ] Validación de estados antes de acciones
- [ ] Validación de permisos (@can)
- [ ] Validación de duplicados (ítems)
- [ ] Validación de varianza (recepción)
- [ ] Almacenes origen ≠ destino

**UX**:
- [ ] Confirmaciones modales en acciones críticas
- [ ] Toast notifications (success/error)
- [ ] Loading states en todos los botones
- [ ] Skeleton loaders durante carga
- [ ] Mensajes informativos claros

**Responsive**:
- [ ] Tablas → cards en mobile
- [ ] Touch targets ≥44px
- [ ] Wizard responsive
- [ ] Modales full-screen en mobile

**Seguridad**:
- [ ] @csrf en formularios
- [ ] Escapar output ({{ }})
- [ ] Validación de autorización
- [ ] No exponer datos sensibles

**Accesibilidad**:
- [ ] Labels asociados a inputs
- [ ] ARIA labels en botones
- [ ] Navegación por teclado
- [ ] Mensajes de error accesibles
- [ ] Focus management en modales

**Performance**:
- [ ] wire:loading.delay para evitar flicker
- [ ] Debounce en búsquedas
- [ ] Paginación con límites
- [ ] Lazy loading de datos pesados

---

**Fecha de Creación**: 31 de Octubre 2025
**Versión**: 1.1 (con validaciones completas)
**Autor**: Claude Code

🎯 **¡Listos para completar Transferencias Frontend con validaciones completas!**
