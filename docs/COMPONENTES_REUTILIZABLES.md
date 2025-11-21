# 🎨 COMPONENTES REUTILIZABLES - BLADE

**Fecha de Creación**: 1 de Noviembre 2025, 00:20
**Creado por**: Claude Code
**Branch**: `feature/reusable-components`
**Ubicación**: `resources/views/components/`

---

## 📦 COMPONENTES DISPONIBLES

### 1. Loading Spinner

**Archivo**: `resources/views/components/loading-spinner.blade.php`

**Descripción**: Spinner para mostrar estados de carga. Compatible con Livewire `wire:loading`.

**Uso**:
```blade
{{-- Básico --}}
<x-loading-spinner />

{{-- Con tamaño --}}
<x-loading-spinner size="sm" />
<x-loading-spinner size="lg" />

{{-- Con color --}}
<x-loading-spinner color="primary" />
<x-loading-spinner color="danger" />

{{-- Con texto --}}
<x-loading-spinner text="Guardando..." />

{{-- Con Livewire --}}
<x-loading-spinner wire:loading wire:target="save" />
<x-loading-spinner wire:loading wire:target="delete" color="danger" text="Eliminando..." />
```

**Props**:
- `size`: `sm`, `md` (default), `lg`
- `color`: `primary`, `secondary`, `success`, `danger`, `warning`, `info`
- `text`: Texto opcional debajo del spinner

---

### 2. Toast Notification

**Archivo**: `resources/views/components/toast-notification.blade.php`

**Descripción**: Sistema de notificaciones toast para feedback al usuario. Usa Alpine.js para animaciones.

**Uso en Blade**:
```blade
{{-- Agregar UNA VEZ en layout principal --}}
<x-toast-notification />
```

**Uso en Livewire**:
```php
// Success
$this->dispatch('notify', type: 'success', message: 'Guardado exitosamente');

// Error
$this->dispatch('notify', type: 'error', message: 'Error al guardar');

// Warning
$this->dispatch('notify', type: 'warning', message: 'Advertencia: RFC ya existe');

// Info
$this->dispatch('notify', type: 'info', message: 'Información adicional');

// Con duración personalizada (default 3000ms)
$this->dispatch('notify', type: 'success', message: 'Guardado', duration: 5000);
```

**Tipos disponibles**: `success`, `error`, `warning`, `info`

**Características**:
- Auto-dismiss después de 3 segundos (configurable)
- Animaciones suaves con Alpine.js
- Ícono automático según tipo
- Botón de cierre manual
- Posicionado en esquina inferior derecha

---

### 3. Search Input

**Archivo**: `resources/views/components/search-input.blade.php`

**Descripción**: Input de búsqueda con ícono de lupa. Compatible con Livewire `wire:model`.

**Uso**:
```blade
{{-- Básico --}}
<x-search-input wire:model.live.debounce.300ms="search" />

{{-- Con placeholder personalizado --}}
<x-search-input
    wire:model.live.debounce.300ms="searchTerm"
    placeholder="Buscar recetas..."
/>

{{-- Con clases adicionales --}}
<x-search-input
    wire:model.live="search"
    class="form-control-lg"
/>
```

**Props**:
- `placeholder`: Texto placeholder (default: "Buscar...")
- `id`: ID único (auto-generado si no se provee)

**Características**:
- Ícono de búsqueda integrado
- Compatible con `wire:model.live` para búsqueda en tiempo real
- Recomendado usar con debounce (300ms)

---

### 4. Status Badge

**Archivo**: `resources/views/components/status-badge.blade.php`

**Descripción**: Badges para mostrar estados con colores e íconos automáticos.

**Uso**:
```blade
{{-- Estados pre-configurados --}}
<x-status-badge status="active" />        {{-- Verde: Activo --}}
<x-status-badge status="inactive" />      {{-- Gris: Inactivo --}}
<x-status-badge status="pending" />       {{-- Amarillo: Pendiente --}}
<x-status-badge status="approved" />      {{-- Verde: Aprobado --}}
<x-status-badge status="rejected" />      {{-- Rojo: Rechazado --}}
<x-status-badge status="in_progress" />   {{-- Azul: En Progreso --}}

{{-- Estado personalizado --}}
<x-status-badge
    status="custom"
    label="Mi Estado"
    color="primary"
/>

{{-- Sin ícono --}}
<x-status-badge status="active" :icon="false" />
```

**Estados pre-configurados**:
| Status | Color | Label | Ícono |
|--------|-------|-------|-------|
| `active` | success (verde) | Activo | check-circle |
| `inactive` | secondary (gris) | Inactivo | x-circle |
| `pending` | warning (amarillo) | Pendiente | clock |
| `approved` | success (verde) | Aprobado | check-circle |
| `rejected` | danger (rojo) | Rechazado | x-circle |
| `in_progress` | info (azul) | En Progreso | arrow-repeat |

**Props**:
- `status`: Estado (usa pre-configurados o `custom`)
- `label`: Label personalizado (override del status)
- `color`: Color personalizado (Bootstrap colors)
- `icon`: Mostrar ícono (default: `true`)

---

### 5. Action Buttons

**Archivo**: `resources/views/components/action-buttons.blade.php`

**Descripción**: Grupo de botones de acción (ver, editar, eliminar). Soporta rutas Laravel y acciones Livewire.

**Uso con Livewire**:
```blade
{{-- Editar y Eliminar --}}
<x-action-buttons
    edit-action="edit({{ $item->id }})"
    delete-action="confirmDelete({{ $item->id }})"
/>

{{-- Solo Editar --}}
<x-action-buttons
    :show-delete="false"
    edit-action="edit({{ $item->id }})"
/>

{{-- Ver, Editar y Eliminar --}}
<x-action-buttons
    :show-view="true"
    view-action="showDetails({{ $item->id }})"
    edit-action="edit({{ $item->id }})"
    delete-action="delete({{ $item->id }})"
/>

{{-- Sin confirmación de delete --}}
<x-action-buttons
    edit-action="edit({{ $item->id }})"
    delete-action="delete({{ $item->id }})"
    :confirm-delete="false"
/>

{{-- Mensaje personalizado de confirmación --}}
<x-action-buttons
    edit-action="edit({{ $item->id }})"
    delete-action="delete({{ $item->id }})"
    delete-message="¿Eliminar esta receta?"
/>
```

**Uso con Rutas Laravel**:
```blade
<x-action-buttons
    edit-route="{{ route('items.edit', $item) }}"
    delete-route="{{ route('items.destroy', $item) }}"
/>

<x-action-buttons
    :show-view="true"
    view-route="{{ route('items.show', $item) }}"
    edit-route="{{ route('items.edit', $item) }}"
    delete-route="{{ route('items.destroy', $item) }}"
/>
```

**Props**:
- `showEdit`: Mostrar botón editar (default: `true`)
- `showDelete`: Mostrar botón eliminar (default: `true`)
- `showView`: Mostrar botón ver (default: `false`)
- `editAction`: Acción Livewire para editar
- `deleteAction`: Acción Livewire para eliminar
- `viewAction`: Acción Livewire para ver
- `editRoute`: Ruta Laravel para editar
- `deleteRoute`: Ruta Laravel para eliminar
- `viewRoute`: Ruta Laravel para ver
- `confirmDelete`: Confirmar antes de eliminar (default: `true`)
- `deleteMessage`: Mensaje de confirmación (default: "¿Está seguro de eliminar este registro?")
- `size`: Tamaño botones: `sm`, `md`, `lg` (default: `sm`)

**Características**:
- Botones agrupados con `btn-group`
- Íconos SVG Bootstrap
- Confirmación JavaScript para delete (opcional)
- Compatible con rutas Laravel (form con @method('DELETE'))
- Compatible con Livewire wire:click

---

## 📝 EJEMPLOS DE USO COMPLETOS

### Ejemplo 1: Listado con Búsqueda y Badges

```blade
<div class="card">
    <div class="card-header">
        <h5>Recetas</h5>
        <x-search-input wire:model.live.debounce.300ms="search" placeholder="Buscar recetas..." />
    </div>
    <div class="card-body">
        <table class="table">
            <thead>
                <tr>
                    <th>Nombre</th>
                    <th>Estado</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
                @foreach($recetas as $receta)
                    <tr>
                        <td>{{ $receta->nombre }}</td>
                        <td>
                            <x-status-badge :status="$receta->activo ? 'active' : 'inactive'" />
                        </td>
                        <td>
                            <x-action-buttons
                                edit-action="edit({{ $receta->id }})"
                                delete-action="confirmDelete({{ $receta->id }})"
                            />
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>
```

### Ejemplo 2: Formulario con Loading y Toast

```blade
<form wire:submit="save">
    <div class="mb-3">
        <label>Nombre</label>
        <input type="text" wire:model.live="nombre" class="form-control">
        @error('nombre') <small class="text-danger">{{ $message }}</small> @enderror
    </div>

    <button type="submit" class="btn btn-primary" wire:loading.attr="disabled">
        <span wire:loading.remove>Guardar</span>
        <span wire:loading>
            <x-loading-spinner size="sm" color="white" />
        </span>
    </button>
</form>

{{-- Toast para notificaciones --}}
<x-toast-notification />
```

```php
// En el componente Livewire
public function save()
{
    $this->validate();

    // Guardar...

    $this->dispatch('notify', type: 'success', message: 'Guardado exitosamente');
}
```

---

## 🎯 BENEFICIOS

✅ **Consistencia**: UI uniforme en toda la aplicación
✅ **Velocidad**: No re-inventar la rueda en cada vista
✅ **Mantenibilidad**: Un cambio afecta todos los usos
✅ **Documentación**: Cada componente está documentado
✅ **Testing**: Más fácil testear componentes aislados

---

## 📦 PRÓXIMOS PASOS PARA QWEN

**Mañana Sábado** en Bloques 2 y 3:

1. **Bloque 2 (Loading States)**:
   - Usar `<x-loading-spinner />` en todos los botones
   - Agregar `<x-toast-notification />` al layout
   - Disparar eventos `notify` en save/delete

2. **Bloque 3 (Responsive Design)**:
   - Ya NO necesitas crear componentes desde cero
   - Solo enfócate en layout responsive (cards mobile)
   - Usar `<x-search-input />` en listados
   - Usar `<x-action-buttons />` en tablas
   - Usar `<x-status-badge />` donde corresponda

---

## ✅ CHECKLIST INTEGRACIÓN

Para usar estos componentes en tus vistas:

- [ ] Importar componentes (Laravel auto-discovery, no require import)
- [ ] Agregar `<x-toast-notification />` UNA VEZ en layout principal
- [ ] Reemplazar spinners custom con `<x-loading-spinner />`
- [ ] Reemplazar botones de acción con `<x-action-buttons />`
- [ ] Reemplazar badges custom con `<x-status-badge />`
- [ ] Reemplazar inputs de búsqueda con `<x-search-input />`

---

**Componentes listos** ✅
**Branch**: `feature/reusable-components`
**Status**: Pushed y listo para merge

Qwen: estos componentes te ahorrarán ~1 hora de trabajo mañana! 🚀
