# 🎨 PROMPT MAESTRO PARA QWEN - FRONTEND SÁBADO

**Agente**: Qwen
**Fecha**: Sábado 1 de noviembre de 2025
**Duración**: 6 horas (09:00 - 15:00)
**Objetivo**: Mejorar UI/UX de Catálogos + Recetas + Crear componentes reutilizables

---

## 🎯 MISIÓN

Tú eres **QWEN**, el especialista en **Frontend y UI/UX** del equipo. Tu misión es:

1. **Mejorar la UI/UX de componentes Livewire existentes** (Catálogos + Recetas)
2. **Crear componentes reutilizables** para el Design System
3. **Agregar validación inline** y feedback visual
4. **Optimizar responsive design** para móviles
5. **Documentar todo** en formato claro

**NO tienes que**:
- Crear backend (eso lo hace Codex)
- Modificar base de datos (ya está normalizada)
- Crear tests unitarios (Codex lo hará domingo)

---

## 📋 CONTEXTO DEL PROYECTO

### Stack Frontend
- **Livewire 3.7**: Componentes reactivos
- **Alpine.js 3.15**: Interactividad ligera
- **Bootstrap 5.3**: Framework CSS
- **Tailwind CSS 3.1**: Utilidades (legacy, evitar usar nuevo)
- **Vite 5.0**: Build tool

### Patrones Actuales
- Layout: `resources/views/layouts/terrena.blade.php` (Bootstrap 5 con sidebar)
- Componentes: `app/Livewire/**/*.php`
- Vistas: `resources/views/livewire/**/*.blade.php`
- Validación: `protected function rules()` en componentes Livewire
- Modales: Bootstrap modals con Alpine.js

### Archivos que YA EXISTEN (no crear de nuevo)

```
✅ YA EXISTE - Solo mejorar/optimizar:
app/Livewire/Catalogs/
├── SucursalesIndex.php
├── AlmacenesIndex.php
├── ProveedoresIndex.php
├── UnidadesIndex.php
├── StockPolicyIndex.php
└── UomConversionIndex.php

app/Livewire/Recipes/
├── RecipesIndex.php
├── RecipeEditor.php
├── PresentacionesIndex.php
└── ConversionesIndex.php

resources/views/livewire/catalogs/
├── sucursales-index.blade.php
├── almacenes-index.blade.php
├── proveedores-index.blade.php
├── unidades-index.blade.php
├── stock-policy-index.blade.php
└── uom-conversion-index.blade.php

resources/views/livewire/recipes/
├── recipes-index.blade.php
├── recipe-editor.blade.php
├── presentaciones-index.blade.php
└── conversiones-index.blade.php
```

---

## ✅ TAREAS DEL SÁBADO (6 horas)

### BLOQUE 1: Validaciones Inline (2 horas - 09:00-11:00)

#### Tarea 1.1: Agregar validación real-time en Catálogos (1h)

**Objetivo**: Mostrar errores de validación EN TIEMPO REAL mientras el usuario escribe.

**Archivos a modificar**:
- `app/Livewire/Catalogs/ProveedoresIndex.php`
- `app/Livewire/Catalogs/SucursalesIndex.php`
- `resources/views/livewire/catalogs/proveedores-index.blade.php`
- `resources/views/livewire/catalogs/sucursales-index.blade.php`

**Ejemplo de implementación**:

**Componente Livewire** (`ProveedoresIndex.php`):
```php
<?php

namespace App\Livewire\Catalogs;

use App\Models\Catalogs\Proveedor;
use Illuminate\Validation\Rule;
use Livewire\Component;
use Livewire\WithPagination;

class ProveedoresIndex extends Component
{
    use WithPagination;

    protected string $paginationTheme = 'bootstrap';

    public string $search = '';
    public ?int $editId = null;
    public string $rfc = '';
    public string $nombre = '';
    public string $telefono = '';
    public string $email = '';
    public bool $activo = true;

    // ✨ NUEVO: Agregar validación en tiempo real
    public function updated($propertyName)
    {
        $this->validateOnly($propertyName);
    }

    protected function rules(): array
    {
        return [
            'rfc'      => [
                'required',
                'string',
                'max:20',
                'regex:/^[A-Z&Ñ]{3,4}\d{6}[A-Z0-9]{3}$/',
                Rule::unique('cat_proveedores', 'rfc')->ignore($this->editId)
            ],
            'nombre'   => ['required','string','max:120'],
            'telefono' => ['nullable','string','max:30','regex:/^\d{10}$/'],
            'email'    => ['nullable','email','max:120'],
            'activo'   => ['boolean'],
        ];
    }

    // ✨ NUEVO: Mensajes personalizados
    protected function messages(): array
    {
        return [
            'rfc.required' => 'El RFC es obligatorio',
            'rfc.regex' => 'El RFC no tiene un formato válido (ej: ABC123456XYZ)',
            'rfc.unique' => 'Este RFC ya está registrado',
            'nombre.required' => 'El nombre es obligatorio',
            'nombre.max' => 'El nombre no puede exceder 120 caracteres',
            'telefono.regex' => 'El teléfono debe tener 10 dígitos',
            'email.email' => 'El email no es válido',
        ];
    }

    // ... resto del código sin cambios
}
```

**Vista Blade** (`proveedores-index.blade.php`):
```blade
<div class="modal-body">
    <!-- RFC -->
    <div class="mb-3">
        <label class="form-label">
            RFC <span class="text-danger">*</span>
        </label>
        <input
            type="text"
            class="form-control @error('rfc') is-invalid @enderror"
            wire:model.live="rfc"
            placeholder="ABC123456XYZ"
            maxlength="20"
        >
        @error('rfc')
            <div class="invalid-feedback d-block">
                <i class="bi bi-exclamation-circle me-1"></i>
                {{ $message }}
            </div>
        @enderror
        @if(!$errors->has('rfc') && strlen($rfc) >= 12)
            <div class="valid-feedback d-block">
                <i class="bi bi-check-circle me-1"></i>
                RFC válido
            </div>
        @endif
    </div>

    <!-- Nombre -->
    <div class="mb-3">
        <label class="form-label">
            Nombre <span class="text-danger">*</span>
            <small class="text-muted">({{ strlen($nombre) }}/120)</small>
        </label>
        <input
            type="text"
            class="form-control @error('nombre') is-invalid @enderror"
            wire:model.live="nombre"
            placeholder="Nombre del proveedor"
            maxlength="120"
        >
        @error('nombre')
            <div class="invalid-feedback d-block">
                {{ $message }}
            </div>
        @enderror
    </div>

    <!-- Teléfono -->
    <div class="mb-3">
        <label class="form-label">Teléfono</label>
        <input
            type="tel"
            class="form-control @error('telefono') is-invalid @enderror"
            wire:model.live="telefono"
            placeholder="5551234567"
            maxlength="10"
        >
        @error('telefono')
            <div class="invalid-feedback d-block">
                {{ $message }}
            </div>
        @enderror
        <small class="form-text text-muted">10 dígitos sin espacios ni guiones</small>
    </div>

    <!-- Email -->
    <div class="mb-3">
        <label class="form-label">Email</label>
        <input
            type="email"
            class="form-control @error('email') is-invalid @enderror"
            wire:model.live="email"
            placeholder="proveedor@example.com"
        >
        @error('email')
            <div class="invalid-feedback d-block">
                {{ $message }}
            </div>
        @enderror
    </div>

    <!-- Activo -->
    <div class="mb-3">
        <div class="form-check form-switch">
            <input
                type="checkbox"
                class="form-check-input"
                id="activo"
                wire:model="activo"
            >
            <label class="form-check-label" for="activo">
                Activo
                @if($activo)
                    <span class="badge bg-success ms-2">Activo</span>
                @else
                    <span class="badge bg-secondary ms-2">Inactivo</span>
                @endif
            </label>
        </div>
    </div>
</div>
```

**Aplica el mismo patrón a**:
- SucursalesIndex
- AlmacenesIndex
- UnidadesIndex
- StockPolicyIndex

---

#### Tarea 1.2: Agregar validación inline en Recetas (1h)

**Archivos a modificar**:
- `app/Livewire/Recipes/RecipeEditor.php`
- `resources/views/livewire/recipes/recipe-editor.blade.php`

**Features a agregar**:
1. Validación en tiempo real de nombre de receta
2. Validación de yield_qty > 0
3. Validación de ingredientes (cantidad > 0, item_id exists)
4. Preview de costo total mientras agrega ingredientes
5. Contador de caracteres en campos de texto

**Ejemplo para RecipeEditor**:

```php
// RecipeEditor.php
public function updatedIngredientes()
{
    // Recalcular costo total automáticamente
    $this->calculateTotalCost();
}

public function calculateTotalCost()
{
    $total = 0;
    foreach ($this->ingredientes as $ing) {
        $item = \App\Models\Item::find($ing['item_id']);
        if ($item) {
            $total += ($ing['cantidad'] ?? 0) * ($item->costo_promedio ?? 0);
        }
    }
    $this->costo_estimado = $total;
}

protected function messages(): array
{
    return [
        'nombre_plato.required' => 'El nombre del plato es obligatorio',
        'nombre_plato.unique' => 'Ya existe una receta con este nombre',
        'yield_qty.required' => 'La cantidad de rendimiento es obligatoria',
        'yield_qty.min' => 'El rendimiento debe ser mayor a 0',
        'ingredientes.required' => 'Debe agregar al menos un ingrediente',
        'ingredientes.*.item_id.required' => 'Debe seleccionar un ítem',
        'ingredientes.*.cantidad.min' => 'La cantidad debe ser mayor a 0',
    ];
}
```

---

### BLOQUE 2: Loading States & Feedback Visual (2 horas - 11:00-13:00)

#### Tarea 2.1: Agregar spinners y loading states (1h)

**Objetivo**: Mostrar feedback visual cuando se están procesando acciones.

**Patrón a implementar**:

```blade
<!-- Ejemplo en modal de guardar proveedor -->
<div class="modal-footer">
    <button
        type="button"
        class="btn btn-secondary"
        data-bs-dismiss="modal"
        wire:loading.attr="disabled"
    >
        Cancelar
    </button>

    <button
        type="button"
        class="btn btn-primary"
        wire:click="save"
        wire:loading.attr="disabled"
        wire:loading.class="disabled"
    >
        <!-- Spinner mientras guarda -->
        <span wire:loading wire:target="save">
            <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
            Guardando...
        </span>

        <!-- Texto normal -->
        <span wire:loading.remove wire:target="save">
            <i class="bi bi-check-circle me-2"></i>
            Guardar
        </span>
    </button>
</div>
```

**Skeleton Loaders para tablas**:

```blade
<!-- Mientras carga la tabla -->
<div wire:loading.delay wire:target="search,page">
    <div class="table-responsive">
        <table class="table">
            <thead><!-- headers normales --></thead>
            <tbody>
                @for($i = 0; $i < 5; $i++)
                    <tr>
                        <td><div class="skeleton skeleton-text"></div></td>
                        <td><div class="skeleton skeleton-text"></div></td>
                        <td><div class="skeleton skeleton-text"></div></td>
                        <td><div class="skeleton skeleton-button"></div></td>
                    </tr>
                @endfor
            </tbody>
        </table>
    </div>
</div>

<!-- Tabla real (oculta mientras carga) -->
<div wire:loading.remove wire:target="search,page">
    <!-- tabla normal -->
</div>
```

**CSS para skeletons** (agregar a `resources/css/app.css`):

```css
/* Loading Skeletons */
.skeleton {
    animation: skeleton-loading 1s linear infinite alternate;
    background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
    background-size: 200% 100%;
    border-radius: 4px;
}

.skeleton-text {
    height: 20px;
    width: 100%;
}

.skeleton-button {
    height: 32px;
    width: 80px;
}

@keyframes skeleton-loading {
    0% {
        background-position: 200% 0;
    }
    100% {
        background-position: -200% 0;
    }
}
```

**Aplicar a todos los componentes de Catálogos y Recetas**.

---

#### Tarea 2.2: Toast Notifications mejoradas (1h)

**Objetivo**: Reemplazar `session()->flash()` con toasts bonitos de Bootstrap 5.

**Crear componente reutilizable**: `resources/views/components/toast-notification.blade.php`

```blade
@if (session()->has('ok') || session()->has('error') || session()->has('warn'))
    <div class="toast-container position-fixed top-0 end-0 p-3" style="z-index: 9999">
        @if(session()->has('ok'))
            <div class="toast align-items-center text-white bg-success border-0 show" role="alert">
                <div class="d-flex">
                    <div class="toast-body">
                        <i class="bi bi-check-circle me-2"></i>
                        {{ session('ok') }}
                    </div>
                    <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
                </div>
            </div>
        @endif

        @if(session()->has('error'))
            <div class="toast align-items-center text-white bg-danger border-0 show" role="alert">
                <div class="d-flex">
                    <div class="toast-body">
                        <i class="bi bi-exclamation-triangle me-2"></i>
                        {{ session('error') }}
                    </div>
                    <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
                </div>
            </div>
        @endif

        @if(session()->has('warn'))
            <div class="toast align-items-center text-white bg-warning border-0 show" role="alert">
                <div class="d-flex">
                    <div class="toast-body">
                        <i class="bi bi-info-circle me-2"></i>
                        {{ session('warn') }}
                    </div>
                    <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
                </div>
            </div>
        @endif
    </div>

    <script>
        // Auto-hide después de 5 segundos
        setTimeout(() => {
            document.querySelectorAll('.toast').forEach(toast => {
                const bsToast = bootstrap.Toast.getOrCreateInstance(toast);
                bsToast.hide();
            });
        }, 5000);
    </script>
@endif
```

**Incluir en layout**: Agregar en `resources/views/layouts/terrena.blade.php` antes del cierre de `</body>`:

```blade
    <!-- Toast Notifications -->
    <x-toast-notification />
</body>
</html>
```

---

### BLOQUE 3: Responsive Design (2 horas - 13:00-15:00)

#### Tarea 3.1: Optimizar tablas para móvil (1h)

**Problema**: Las tablas se rompen en pantallas pequeñas.

**Solución**: Usar tablas responsivas con scroll horizontal + cards en móvil.

**Patrón Desktop (>=768px)**:

```blade
<!-- Vista Desktop: Tabla normal -->
<div class="d-none d-md-block">
    <div class="table-responsive">
        <table class="table table-hover">
            <thead class="table-light">
                <tr>
                    <th>RFC</th>
                    <th>Nombre</th>
                    <th>Teléfono</th>
                    <th>Email</th>
                    <th>Estado</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
                @forelse ($proveedores as $proveedor)
                    <tr>
                        <td>{{ $proveedor->rfc }}</td>
                        <td>{{ $proveedor->nombre }}</td>
                        <td>{{ $proveedor->telefono }}</td>
                        <td>{{ $proveedor->email }}</td>
                        <td>
                            @if($proveedor->activo)
                                <span class="badge bg-success">Activo</span>
                            @else
                                <span class="badge bg-secondary">Inactivo</span>
                            @endif
                        </td>
                        <td>
                            <button class="btn btn-sm btn-primary" wire:click="edit({{ $proveedor->id }})">
                                <i class="bi bi-pencil"></i>
                            </button>
                            <button class="btn btn-sm btn-danger" wire:click="delete({{ $proveedor->id }})">
                                <i class="bi bi-trash"></i>
                            </button>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="text-center text-muted">
                            No hay proveedores registrados
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
```

**Patrón Mobile (<768px)**:

```blade
<!-- Vista Mobile: Cards -->
<div class="d-md-none">
    @forelse ($proveedores as $proveedor)
        <div class="card mb-3">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-start mb-2">
                    <h6 class="card-title mb-0">{{ $proveedor->nombre }}</h6>
                    @if($proveedor->activo)
                        <span class="badge bg-success">Activo</span>
                    @else
                        <span class="badge bg-secondary">Inactivo</span>
                    @endif
                </div>

                <div class="small text-muted mb-2">
                    <div><strong>RFC:</strong> {{ $proveedor->rfc }}</div>
                    @if($proveedor->telefono)
                        <div><strong>Tel:</strong> {{ $proveedor->telefono }}</div>
                    @endif
                    @if($proveedor->email)
                        <div><strong>Email:</strong> {{ $proveedor->email }}</div>
                    @endif
                </div>

                <div class="btn-group btn-group-sm w-100">
                    <button class="btn btn-outline-primary" wire:click="edit({{ $proveedor->id }})">
                        <i class="bi bi-pencil"></i> Editar
                    </button>
                    <button class="btn btn-outline-danger" wire:click="delete({{ $proveedor->id }})">
                        <i class="bi bi-trash"></i> Eliminar
                    </button>
                </div>
            </div>
        </div>
    @empty
        <div class="alert alert-info">
            No hay proveedores registrados
        </div>
    @endforelse
</div>
```

**Aplicar este patrón a**:
- Proveedores
- Sucursales
- Almacenes
- Recetas

---

#### Tarea 3.2: Optimizar modales para móvil (1h)

**Problema**: Los modales se ven mal en móviles.

**Solución**: Hacer modales full-screen en móvil.

**CSS a agregar** (`resources/css/app.css`):

```css
/* Modal full-screen en móviles */
@media (max-width: 767.98px) {
    .modal-dialog {
        margin: 0;
        max-width: 100%;
        height: 100vh;
    }

    .modal-content {
        height: 100vh;
        border-radius: 0;
    }

    .modal-body {
        overflow-y: auto;
        max-height: calc(100vh - 120px);
    }
}

/* Inputs más grandes en móvil para mejor touch */
@media (max-width: 767.98px) {
    .form-control,
    .form-select {
        font-size: 16px; /* Evita zoom en iOS */
        padding: 12px;
    }

    .btn {
        padding: 12px 20px;
        font-size: 16px;
    }
}
```

**Mejorar header de modal**:

```blade
<div class="modal-header">
    <h5 class="modal-title">
        <i class="bi bi-{{ $editId ? 'pencil' : 'plus-circle' }} me-2"></i>
        {{ $editId ? 'Editar' : 'Nuevo' }} Proveedor
    </h5>
    <button
        type="button"
        class="btn-close"
        data-bs-dismiss="modal"
        aria-label="Close"
    ></button>
</div>
```

---

## 📦 COMPONENTES REUTILIZABLES A CREAR

### 1. SearchInput Component

**Archivo**: `resources/views/components/search-input.blade.php`

```blade
@props(['placeholder' => 'Buscar...', 'model' => 'search'])

<div class="input-group">
    <span class="input-group-text bg-white">
        <i class="bi bi-search"></i>
    </span>
    <input
        type="text"
        class="form-control border-start-0"
        placeholder="{{ $placeholder }}"
        wire:model.live.debounce.300ms="{{ $model }}"
    >
    @if($model && strlen($model) > 0)
        <button
            class="btn btn-outline-secondary"
            type="button"
            wire:click="$set('{{ $model }}', '')"
        >
            <i class="bi bi-x-lg"></i>
        </button>
    @endif
</div>
```

**Uso**:
```blade
<x-search-input placeholder="Buscar proveedores..." />
```

---

### 2. StatusBadge Component

**Archivo**: `resources/views/components/status-badge.blade.php`

```blade
@props(['active' => true, 'labels' => ['Activo', 'Inactivo']])

@if($active)
    <span {{ $attributes->merge(['class' => 'badge bg-success']) }}>
        <i class="bi bi-check-circle me-1"></i>
        {{ $labels[0] }}
    </span>
@else
    <span {{ $attributes->merge(['class' => 'badge bg-secondary']) }}>
        <i class="bi bi-x-circle me-1"></i>
        {{ $labels[1] }}
    </span>
@endif
```

**Uso**:
```blade
<x-status-badge :active="$proveedor->activo" />
```

---

### 3. ActionButtons Component

**Archivo**: `resources/views/components/action-buttons.blade.php`

```blade
@props(['editAction', 'deleteAction', 'size' => 'sm'])

<div class="btn-group btn-group-{{ $size }}">
    <button
        class="btn btn-primary"
        wire:click="{{ $editAction }}"
        title="Editar"
    >
        <i class="bi bi-pencil"></i>
        <span class="d-none d-lg-inline ms-1">Editar</span>
    </button>

    <button
        class="btn btn-danger"
        wire:click="{{ $deleteAction }}"
        wire:confirm="¿Está seguro de eliminar este registro?"
        title="Eliminar"
    >
        <i class="bi bi-trash"></i>
        <span class="d-none d-lg-inline ms-1">Eliminar</span>
    </button>
</div>
```

**Uso**:
```blade
<x-action-buttons
    editAction="edit({{ $proveedor->id }})"
    deleteAction="delete({{ $proveedor->id }})"
/>
```

---

### 4. EmptyState Component

**Archivo**: `resources/views/components/empty-state.blade.php`

```blade
@props([
    'icon' => 'inbox',
    'title' => 'No hay registros',
    'description' => 'No se encontraron resultados',
    'actionLabel' => null,
    'actionClick' => null
])

<div class="text-center py-5">
    <i class="bi bi-{{ $icon }} text-muted" style="font-size: 4rem;"></i>
    <h5 class="mt-3 text-muted">{{ $title }}</h5>
    <p class="text-muted">{{ $description }}</p>

    @if($actionLabel && $actionClick)
        <button
            class="btn btn-primary mt-2"
            wire:click="{{ $actionClick }}"
        >
            <i class="bi bi-plus-circle me-2"></i>
            {{ $actionLabel }}
        </button>
    @endif
</div>
```

**Uso**:
```blade
<x-empty-state
    icon="people"
    title="No hay proveedores"
    description="Comienza agregando tu primer proveedor"
    actionLabel="Nuevo Proveedor"
    actionClick="create"
/>
```

---

## ✅ CHECKLIST DE VALIDACIÓN

Antes de terminar cada bloque, verifica:

### Bloque 1: Validaciones
- [ ] Todos los campos tienen `wire:model.live` para validación en tiempo real
- [ ] Mensajes de error personalizados en español
- [ ] Indicadores visuales (rojo/verde) funcionan correctamente
- [ ] Contador de caracteres en campos con límite
- [ ] Regex de RFC, teléfono, email funcionan

### Bloque 2: Loading States
- [ ] Spinners aparecen en botones durante acciones
- [ ] Skeleton loaders funcionan en tablas
- [ ] Botones se deshabilitan durante loading
- [ ] Toasts aparecen y desaparecen automáticamente
- [ ] Toasts tienen colores correctos (verde success, rojo error, amarillo warn)

### Bloque 3: Responsive
- [ ] Tablas se ven bien en desktop (>=768px)
- [ ] Cards se muestran en móvil (<768px)
- [ ] Modales son full-screen en móvil
- [ ] Inputs tienen tamaño 16px en móvil (evita zoom iOS)
- [ ] Botones tienen buen tamaño touch (min 44x44px)

### Componentes Reutilizables
- [ ] SearchInput funciona con debounce 300ms
- [ ] StatusBadge muestra colores correctos
- [ ] ActionButtons tienen confirm en delete
- [ ] EmptyState se muestra cuando no hay datos

---

## 🚨 ERRORES COMUNES A EVITAR

1. **NO uses Tailwind CSS nuevo** (solo Bootstrap 5)
2. **NO modifiques migraciones** (BD ya normalizada)
3. **NO cambies nombres de métodos públicos** en componentes (podrían romper rutas)
4. **NO elimines código funcional** (solo agrega/mejora)
5. **Siempre usa `wire:model.live`** para validación real-time (no `wire:model.defer`)
6. **Usa `@error('campo')` directo** en Blade (ya disponible en Livewire)
7. **NO uses jQuery** (todo con Alpine.js o Livewire)

---

## 📁 ESTRUCTURA DE ENTREGA

Al terminar, debes tener modificados/creados:

```
MODIFICADOS (mejorados):
app/Livewire/Catalogs/
├── ProveedoresIndex.php ✅
├── SucursalesIndex.php ✅
├── AlmacenesIndex.php ✅
└── (resto igual)

app/Livewire/Recipes/
├── RecipeEditor.php ✅
└── RecipesIndex.php ✅

resources/views/livewire/catalogs/
├── proveedores-index.blade.php ✅
├── sucursales-index.blade.php ✅
├── almacenes-index.blade.php ✅
└── (resto igual)

resources/views/livewire/recipes/
├── recipe-editor.blade.php ✅
└── recipes-index.blade.php ✅

CREADOS (nuevos):
resources/views/components/
├── search-input.blade.php 🆕
├── status-badge.blade.php 🆕
├── action-buttons.blade.php 🆕
├── empty-state.blade.php 🆕
└── toast-notification.blade.php 🆕

resources/css/
└── app.css (agregar skeletons + responsive) ✅
```

---

## 🎯 META FINAL

**Al final del sábado a las 15:00**, el sistema debe tener:

✅ Validación inline funcionando en todos los formularios
✅ Feedback visual inmediato (rojo/verde en inputs)
✅ Loading states en todas las acciones
✅ Toasts bonitos reemplazando flash messages
✅ Tablas responsive (desktop table, mobile cards)
✅ Modales optimizados para móvil
✅ 5 componentes reutilizables creados

**¡ÉXITO! 🚀** Si terminas antes de tiempo, puedes:
- Agregar más animaciones sutiles (transitions CSS)
- Mejorar accesibilidad (ARIA labels)
- Optimizar performance (lazy loading de modales)

**¿Preguntas durante el trabajo?** Revisa:
- Documentación ya creada en `docs/UI-UX/MASTER/`
- Código existente en `app/Livewire/` como referencia
- API docs en `docs/UI-UX/MASTER/10_API_SPECS/`

**¡A trabajar! Tienes 6 horas para hacer magia con el frontend! ✨**
