---
description: Estándares de desarrollo frontend para TerrenaLaravel — Livewire 3.7, Alpine.js 3, Bootstrap 5. Incluye convenciones de componentes, UX patterns, accesibilidad y testing. Aplica a todos los agentes.
globs: ["app/Livewire/**/*.php", "resources/views/**/*.blade.php", "resources/js/**/*.js"]
alwaysApply: true
---

# Frontend Standards — TerrenaLaravel

---

## 1. Stack técnico

- **Livewire 3.7** — componentes reactivos PHP/HTML (no JavaScript puro)
- **Alpine.js 3** — interactividad ligera del lado del cliente
- **Bootstrap 5** — CSS framework para layout y componentes UI
- **Blade** — motor de templates de Laravel
- **Vite** — bundler y dev server
- **Chart.js** — gráficas y visualizaciones
- **Cleave.js** — formateo de inputs (moneda, fechas)

---

## 2. Layout y estructura

### Layout obligatorio para componentes nuevos
```blade
{{-- SIEMPRE usar terrena.blade.php para componentes nuevos --}}
@extends('layouts.terrena')

{{-- NUNCA usar app.blade.php (legacy Tailwind) para cosas nuevas --}}
```

### Estructura de página estándar
```blade
@section('content')
<div class="container-fluid py-4">

    {{-- Header con título y acciones --}}
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h4 class="mb-0">Título del Módulo</h4>
            <small class="text-muted">Descripción breve</small>
        </div>
        <div class="d-flex gap-2">
            <button class="btn btn-primary btn-sm" wire:click="create">
                <i class="bi bi-plus-lg"></i> Nuevo
            </button>
        </div>
    </div>

    {{-- Contenido principal --}}
    <div class="card shadow-sm">
        <div class="card-body">
            ...
        </div>
    </div>

</div>
@endsection
```

---

## 3. Componentes Livewire

### Estructura de clase Livewire
```php
<?php

namespace App\Livewire\Inventory;

use Livewire\Component;
use Livewire\WithPagination;
use App\Services\Inventory\ReceptionService;

class ReceptionsIndex extends Component
{
    use WithPagination;

    // Propiedades públicas (reactive)
    public string $search = '';
    public string $estado = '';
    public bool $showModal = false;

    // Propiedades del formulario
    public array $form = [
        'fecha' => '',
        'almacen_id' => '',
        'proveedor_id' => '',
    ];

    // Listeners de eventos
    protected $listeners = ['receptionSaved' => '$refresh'];

    public function updatingSearch(): void
    {
        $this->resetPage();
    }

    public function save(ReceptionService $service): void
    {
        $this->validate([
            'form.fecha' => 'required|date',
            'form.almacen_id' => 'required|integer',
        ]);

        $service->createReception($this->form, []);
        $this->showModal = false;
        $this->reset('form');
        $this->dispatch('reception-saved');
        session()->flash('success', 'Recepción creada exitosamente.');
    }

    public function render(): \Illuminate\View\View
    {
        return view('livewire.inventory.receptions-index', [
            'receptions' => Reception::with(['almacen', 'proveedor'])
                ->when($this->search, fn($q) => $q->where('folio', 'ilike', "%{$this->search}%"))
                ->when($this->estado, fn($q) => $q->where('estado', $this->estado))
                ->orderByDesc('fecha')
                ->paginate(15),
        ]);
    }
}
```

### Naming de componentes
| Tipo | Formato | Ejemplo |
|------|---------|---------|
| Índice/listado | `{Modulo}Index` | `ReceptionsIndex` |
| Creación | `{Modulo}Create` | `ReceptionCreate` |
| Detalle/edición | `{Modulo}Detail` | `ReceptionDetail` |
| Subcomponente | `{Modulo}{Función}` | `ReceptionLineForm` |

### Localización de archivos
```
app/Livewire/{Modulo}/{Componente}.php
resources/views/livewire/{modulo}/{componente}.blade.php
```

---

## 4. Estado de carga y errores (obligatorio)

Todo componente que haga operaciones async DEBE manejar estados de carga y error.

### En Livewire (PHP)
```php
public bool $loading = false;
public ?string $errorMessage = null;

public function save(): void
{
    $this->loading = true;
    $this->errorMessage = null;

    try {
        $this->validate([...]);
        $this->service->process($this->form);
        session()->flash('success', 'Guardado correctamente.');
        $this->showModal = false;
    } catch (\Exception $e) {
        $this->errorMessage = 'Error al guardar: ' . $e->getMessage();
    } finally {
        $this->loading = false;
    }
}
```

### En Blade (UI)
```blade
{{-- Feedback de éxito --}}
@if (session('success'))
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        {{ session('success') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
@endif

{{-- Feedback de error --}}
@if ($errorMessage)
    <div class="alert alert-danger" role="alert">
        <i class="bi bi-exclamation-triangle-fill me-2"></i>{{ $errorMessage }}
    </div>
@endif

{{-- Botón con estado de carga --}}
<button class="btn btn-primary" wire:click="save" wire:loading.attr="disabled">
    <span wire:loading wire:target="save" class="spinner-border spinner-border-sm me-1"></span>
    <span wire:loading.remove wire:target="save"><i class="bi bi-check-lg me-1"></i></span>
    Guardar
</button>
```

---

## 5. Formularios

### Estructura estándar de modal
```blade
<div class="modal fade" id="formModal" tabindex="-1" wire:ignore.self>
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Título del Formulario</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <form wire:submit.prevent="save">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">
                                Fecha <span class="text-danger">*</span>
                            </label>
                            <input type="date"
                                   class="form-control @error('form.fecha') is-invalid @enderror"
                                   wire:model="form.fecha">
                            @error('form.fecha')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                    Cancelar
                </button>
                <button type="button" class="btn btn-primary" wire:click="save"
                        wire:loading.attr="disabled">
                    <span wire:loading wire:target="save"
                          class="spinner-border spinner-border-sm me-1"></span>
                    Guardar
                </button>
            </div>
        </div>
    </div>
</div>
```

### Validación en tiempo real
```php
// Usar $rules para validación on-the-fly con wire:model.live
protected $rules = [
    'form.fecha' => 'required|date',
    'form.qty' => 'required|numeric|min:0.001',
];

// Trigger en campo específico
public function updatedFormQty(): void
{
    $this->validateOnly('form.qty');
}
```

---

## 6. Tablas y listados

### Estructura estándar con búsqueda y paginación
```blade
{{-- Filtros --}}
<div class="row g-2 mb-3">
    <div class="col-md-4">
        <div class="input-group input-group-sm">
            <span class="input-group-text"><i class="bi bi-search"></i></span>
            <input type="text" class="form-control" placeholder="Buscar..."
                   wire:model.live.debounce.300ms="search">
        </div>
    </div>
    <div class="col-md-2">
        <select class="form-select form-select-sm" wire:model.live="estado">
            <option value="">Todos los estados</option>
            <option value="BORRADOR">Borrador</option>
            <option value="POSTEADA">Posteada</option>
        </select>
    </div>
</div>

{{-- Tabla --}}
<div class="table-responsive">
    <table class="table table-hover table-sm align-middle">
        <thead class="table-light">
            <tr>
                <th>Folio</th>
                <th>Fecha</th>
                <th>Estado</th>
                <th class="text-end">Acciones</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($items as $item)
            <tr>
                <td class="fw-semibold">{{ $item->folio }}</td>
                <td>{{ $item->fecha->format('d/m/Y') }}</td>
                <td>
                    <span class="badge bg-{{ $item->estado === 'POSTEADA' ? 'success' : 'secondary' }}">
                        {{ $item->estado }}
                    </span>
                </td>
                <td class="text-end">
                    <button class="btn btn-sm btn-outline-primary"
                            wire:click="view({{ $item->id }})"
                            title="Ver detalle">
                        <i class="bi bi-eye"></i>
                    </button>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="4" class="text-center text-muted py-4">
                    <i class="bi bi-inbox fs-3 d-block mb-2"></i>
                    No hay registros que mostrar
                </td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>

{{-- Paginación --}}
<div class="d-flex justify-content-between align-items-center mt-3">
    <small class="text-muted">
        Mostrando {{ $items->firstItem() }}–{{ $items->lastItem() }}
        de {{ $items->total() }} registros
    </small>
    {{ $items->links() }}
</div>
```

---

## 7. Alpine.js — uso correcto

Alpine.js es para interactividad **del lado del cliente** que no requiere servidor: toggles, dropdowns, animaciones, confirmaciones de eliminación.

```blade
{{-- Toggle de sección --}}
<div x-data="{ open: false }">
    <button class="btn btn-link" @click="open = !open">
        <span x-text="open ? 'Ocultar' : 'Ver detalle'"></span>
        <i class="bi" :class="open ? 'bi-chevron-up' : 'bi-chevron-down'"></i>
    </button>
    <div x-show="open" x-transition>
        {{-- contenido --}}
    </div>
</div>

{{-- Confirmación de acción destructiva --}}
<button class="btn btn-sm btn-danger"
        x-data
        @click="if(confirm('¿Confirma eliminar este registro?')) $wire.delete({{ $item->id }})">
    <i class="bi bi-trash"></i>
</button>
```

**Regla**: Si necesita ir al servidor (datos, lógica de negocio), usar `wire:`. Si es solo UI, usar `x-`.

---

## 8. Accesibilidad (mínimo obligatorio)

```blade
{{-- aria-label en botones de solo icono --}}
<button class="btn btn-sm btn-primary" wire:click="edit({{ $id }})"
        aria-label="Editar registro {{ $folio }}">
    <i class="bi bi-pencil" aria-hidden="true"></i>
</button>

{{-- Roles en tablas --}}
<table class="table" role="grid" aria-label="Listado de recepciones">

{{-- Labels explícitos en forms (no solo placeholder) --}}
<label for="campo-fecha" class="form-label">Fecha de recepción</label>
<input id="campo-fecha" type="date" class="form-control" wire:model="form.fecha">

{{-- Estados de carga accesibles --}}
<span wire:loading wire:target="save" class="spinner-border spinner-border-sm"
      role="status" aria-label="Guardando..."></span>
```

---

## 9. Performance

### Lazy loading de componentes pesados
```blade
{{-- Para componentes con mucha data --}}
<livewire:reports.sales-summary lazy />
```

### Debounce en búsquedas
```blade
{{-- Evitar request en cada tecla --}}
<input wire:model.live.debounce.400ms="search">
```

### Evitar propiedades reactive innecesarias
```php
// MAL: propiedad pública que genera reactivity innecesaria
public Collection $allItems; // Se re-renderiza en cada cambio

// BIEN: computar en render()
public function render(): View
{
    return view('...', ['items' => $this->buildQuery()->paginate(15)]);
}
```

### wire:key en loops
```blade
{{-- Obligatorio en listas dinámicas para evitar re-renders completos --}}
@foreach ($lines as $index => $line)
    <div wire:key="line-{{ $index }}">
        ...
    </div>
@endforeach
```

---

## 10. Testing frontend (E2E)

### Qué testear
- Flujo completo de creación de registro
- Validación de formulario (campos requeridos, errores)
- Paginación y filtros de búsqueda
- Transiciones de estado (Borrador → Posteada)
- Mensajes de éxito/error visibles para el usuario

### Con Laravel Dusk (si se activa)
```php
// tests/Browser/ReceptionTest.php
public function test_can_create_reception(): void
{
    $this->browse(function (Browser $browser) {
        $browser->loginAs(User::factory()->create())
                ->visit('/inventory/receptions/create')
                ->type('@fecha', '2026-05-12')
                ->select('@almacen', '1')
                ->press('Guardar')
                ->assertSee('Recepción creada exitosamente.');
    });
}
```

### Con Livewire Testing (unit)
```php
// Test de componente sin browser
public function test_search_filters_results(): void
{
    $item = Reception::factory()->create(['folio' => 'REC-001']);

    Livewire::test(ReceptionsIndex::class)
            ->set('search', 'REC-001')
            ->assertSee('REC-001');
}
```

---

## 11. Anti-patrones a evitar

| Anti-patrón | Alternativa |
|-------------|-------------|
| Usar `app.blade.php` para nuevo componente | Usar `terrena.blade.php` |
| Lógica de negocio en Blade (`@php`) | Mover a Livewire component o Service |
| Query directa en Blade | Pasar datos desde `render()` |
| Hardcodear URLs en JS/Blade | Usar `route('nombre')` o `url()` |
| No manejar estado de carga | Siempre agregar `wire:loading` en acciones |
| Tabla sin `@forelse` + empty state | Siempre mostrar mensaje cuando no hay datos |
| Botón sin feedback visual al hacer click | Usar `wire:loading.attr="disabled"` |
| Input de búsqueda sin debounce | Siempre `debounce.300ms` o más |
| Componente sin paginación en listas | Siempre usar `WithPagination` en listados |
