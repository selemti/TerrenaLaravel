# 📝 EJEMPLO: Delegación de Tarea - Módulo Inventario

**Tarea**: Crear página de listado de items con filtros y paginación  
**IA Destino**: Claude / Qwen / ChatGPT  
**Estimación**: M (1-2 días)  
**Prioridad**: 🔴 CRÍTICO

---

## 🎯 PROMPT COMPLETO LISTO PARA COPIAR

```markdown
# CONTEXTO DEL PROYECTO: TerrenaLaravel ERP

## 🏢 Visión General

TerrenaLaravel es un **ERP para restaurantes** que centraliza:
- Gestión de inventario multi-almacén
- Compras automatizadas (reposición inteligente)
- Recetas versionadas multinivel
- Producción con trazabilidad
- Caja chica y gastos
- Reportería avanzada
- Integración nativa con **FloreantPOS**

**Industria**: Restaurantes, Food Service  
**Usuarios**: Gerentes de operaciones, personal de cocina, administradores  
**Stack**: Laravel 11, Livewire 3, Alpine.js, Tailwind CSS, PostgreSQL 9.5

---

## 🏗️ ARQUITECTURA Y TECNOLOGÍAS

### Backend
- **Framework**: Laravel 11 (PHP 8.2+)
- **Database**: PostgreSQL 9.5 (esquema `selemti`)
- **ORM**: Eloquent
- **Autenticación**: Laravel Breeze + Spatie Permissions

### Frontend
- **Framework UI**: Livewire 3 (componentes reactivos)
- **Templating**: Blade
- **JS**: Alpine.js (interactividad ligera)
- **CSS**: Tailwind CSS + Bootstrap 5 (legacy components)
- **Build**: Vite

### Estructura Relevante
```
app/
├── Http/
│   ├── Controllers/ItemController.php (existe, mejorar)
│   └── Livewire/Items/ (crear componentes)
├── Models/Item.php (existe)
└── Services/ItemService.php (existe)

resources/
└── views/
    ├── items/
    │   └── index.blade.php (mejorar)
    └── livewire/
        └── items/ (crear)
```

---

## 📊 ESTADO ACTUAL DEL PROYECTO

### Módulo Inventario Actual

**Backend (70% completo)**:
- ✅ Modelo `Item` funcional con relaciones
- ✅ `ItemService` con lógica básica
- ✅ API endpoints básicos funcionando
- 🟡 Controller con CRUD básico (necesita refinamiento)

**Frontend (70% completo)**:
- ✅ Listado básico funcionando
- 🔴 Filtros avanzados faltantes
- 🔴 Paginación no implementada
- 🔴 UX mejorable (diseño inconsistente)

**Base de Datos (95% completo)**:
- ✅ Tabla `items` normalizada (Phase 2.3 completada)
- ✅ FKs a `categories`, `units`, `warehouses`
- ✅ Índices optimizados

---

## 📚 DOCUMENTACIÓN DISPONIBLE

**CRÍTICO**: Consulta estos documentos primero:

1. **`docs/UI-UX/MASTER/02_MODULOS/Inventario.md`** - Specs completas del módulo
2. **`docs/UI-UX/MASTER/03_ARQUITECTURA/02_DESIGN_SYSTEM.md`** - Componentes UI/UX
3. **`docs/UI-UX/MASTER/03_ARQUITECTURA/04_DATABASE_SCHEMA.md`** - Schema BD
4. **`docs/UI-UX/MASTER/05_SPECS_TECNICAS/COMPONENTES_LIVEWIRE.md`** - Patrones Livewire

---

## 🎯 TAREA ESPECÍFICA

### Módulo: Inventario

### Componente: Listado de Items (items/index)

### Descripción de la Tarea

**Mejorar la página de listado de items con:**

1. **Filtros avanzados**:
   - Búsqueda por nombre/código
   - Filtro por categoría (dropdown)
   - Filtro por estado (activo/inactivo)
   - Filtro por almacén
   - Botón "Limpiar filtros"

2. **Tabla optimizada**:
   - Paginación (20 items por página)
   - Ordenamiento por columnas (nombre, código, categoría, stock)
   - Indicadores visuales de stock bajo (badge rojo si stock < stock_min)
   - Acciones rápidas (editar, ver, eliminar)

3. **UX mejorada**:
   - Loading states mientras carga datos
   - Mensajes cuando no hay resultados
   - Botón "Nuevo Item" destacado
   - Diseño responsive (mobile-friendly)
   - Colores consistentes con el design system

### Contexto Adicional

**Problema actual**:
- El listado actual es básico y sin filtros
- Los usuarios pierden tiempo buscando items manualmente
- No hay feedback visual del estado del stock
- No es responsive en móviles

**Resultado esperado**:
- UI moderna y profesional similar a Odoo/Oracle
- Filtros que permitan encontrar items en <5 segundos
- Indicadores visuales claros del estado de stock
- Experiencia fluida en desktop y móviles

---

## 📋 ESPECIFICACIONES TÉCNICAS

### Modelos Involucrados

```php
// Item.php (existe)
class Item extends Model
{
    protected $table = 'items';
    
    // Relaciones existentes
    public function category() // → categories
    public function unit() // → units
    public function stockByWarehouse() // → item_stock
    
    // Scopes que puedes usar
    public function scopeActive($query) // items activos
    public function scopeByCategory($query, $categoryId)
    public function scopeSearch($query, $term) // busca nombre/código
}

// Category.php (existe)
class Category extends Model
{
    protected $table = 'categories';
}

// Warehouse.php (existe)
class Warehouse extends Model
{
    protected $table = 'warehouses';
}
```

### Componente Livewire a Crear

```php
// app/Http/Livewire/Items/ItemList.php
<?php

namespace App\Http\Livewire\Items;

use Livewire\Component;
use Livewire\WithPagination;
use App\Models\Item;
use App\Models\Category;
use App\Models\Warehouse;

class ItemList extends Component
{
    use WithPagination;
    
    // Propiedades públicas (filtros)
    public $search = '';
    public $categoryFilter = '';
    public $statusFilter = '';
    public $warehouseFilter = '';
    
    // Propiedades de ordenamiento
    public $sortField = 'name';
    public $sortDirection = 'asc';
    
    // Listeners
    protected $listeners = ['itemDeleted' => '$refresh'];
    
    public function render()
    {
        $items = Item::query()
            ->with(['category', 'unit'])
            ->when($this->search, function($q) {
                $q->search($this->search);
            })
            ->when($this->categoryFilter, function($q) {
                $q->where('category_id', $this->categoryFilter);
            })
            ->when($this->statusFilter !== '', function($q) {
                $q->where('is_active', $this->statusFilter);
            })
            ->orderBy($this->sortField, $this->sortDirection)
            ->paginate(20);
        
        return view('livewire.items.item-list', [
            'items' => $items,
            'categories' => Category::all(),
            'warehouses' => Warehouse::all(),
        ]);
    }
    
    public function clearFilters()
    {
        $this->reset(['search', 'categoryFilter', 'statusFilter', 'warehouseFilter']);
    }
    
    public function sortBy($field)
    {
        if ($this->sortField === $field) {
            $this->sortDirection = $this->sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            $this->sortField = $field;
            $this->sortDirection = 'asc';
        }
    }
}
```

### Vista Livewire a Crear

```blade
{{-- resources/views/livewire/items/item-list.blade.php --}}
<div class="space-y-4">
    {{-- Filtros --}}
    <div class="bg-white rounded-lg shadow p-4">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
            {{-- Búsqueda --}}
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                    Buscar
                </label>
                <input 
                    type="text" 
                    wire:model.live.debounce.300ms="search"
                    placeholder="Nombre o código..."
                    class="w-full rounded-md border-gray-300 shadow-sm"
                >
            </div>
            
            {{-- Categoría --}}
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                    Categoría
                </label>
                <select wire:model.live="categoryFilter" class="w-full rounded-md border-gray-300 shadow-sm">
                    <option value="">Todas</option>
                    @foreach($categories as $category)
                        <option value="{{ $category->id }}">{{ $category->name }}</option>
                    @endforeach
                </select>
            </div>
            
            {{-- Estado --}}
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                    Estado
                </label>
                <select wire:model.live="statusFilter" class="w-full rounded-md border-gray-300 shadow-sm">
                    <option value="">Todos</option>
                    <option value="1">Activos</option>
                    <option value="0">Inactivos</option>
                </select>
            </div>
            
            {{-- Acciones --}}
            <div class="flex items-end gap-2">
                <button 
                    wire:click="clearFilters"
                    class="px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300"
                >
                    Limpiar
                </button>
                <a 
                    href="{{ route('items.create') }}"
                    class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                >
                    + Nuevo Item
                </a>
            </div>
        </div>
    </div>
    
    {{-- Tabla --}}
    <div class="bg-white rounded-lg shadow overflow-hidden">
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th wire:click="sortBy('code')" class="px-4 py-3 text-left cursor-pointer hover:bg-gray-100">
                            Código
                            @if($sortField === 'code')
                                <span>{{ $sortDirection === 'asc' ? '↑' : '↓' }}</span>
                            @endif
                        </th>
                        <th wire:click="sortBy('name')" class="px-4 py-3 text-left cursor-pointer hover:bg-gray-100">
                            Nombre
                            @if($sortField === 'name')
                                <span>{{ $sortDirection === 'asc' ? '↑' : '↓' }}</span>
                            @endif
                        </th>
                        <th class="px-4 py-3 text-left">Categoría</th>
                        <th class="px-4 py-3 text-right">Stock</th>
                        <th class="px-4 py-3 text-center">Estado</th>
                        <th class="px-4 py-3 text-center">Acciones</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                    @forelse($items as $item)
                        <tr class="hover:bg-gray-50">
                            <td class="px-4 py-3 text-sm">{{ $item->code }}</td>
                            <td class="px-4 py-3 text-sm font-medium">{{ $item->name }}</td>
                            <td class="px-4 py-3 text-sm">{{ $item->category->name ?? 'N/A' }}</td>
                            <td class="px-4 py-3 text-sm text-right">
                                @php
                                    $stock = $item->stockByWarehouse()->sum('quantity');
                                    $isLowStock = $stock < ($item->stock_min ?? 0);
                                @endphp
                                <span class="
                                    px-2 py-1 rounded-full text-xs font-semibold
                                    {{ $isLowStock ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800' }}
                                ">
                                    {{ number_format($stock, 2) }} {{ $item->unit->symbol ?? '' }}
                                </span>
                            </td>
                            <td class="px-4 py-3 text-center">
                                <span class="
                                    px-2 py-1 rounded-full text-xs font-semibold
                                    {{ $item->is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800' }}
                                ">
                                    {{ $item->is_active ? 'Activo' : 'Inactivo' }}
                                </span>
                            </td>
                            <td class="px-4 py-3 text-center">
                                <div class="flex items-center justify-center gap-2">
                                    <a href="{{ route('items.edit', $item) }}" class="text-blue-600 hover:text-blue-800">
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                                        </svg>
                                    </a>
                                    <button 
                                        wire:click="$dispatch('confirmDelete', { itemId: {{ $item->id }} })"
                                        class="text-red-600 hover:text-red-800"
                                    >
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                                        </svg>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-4 py-8 text-center text-gray-500">
                                <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"/>
                                </svg>
                                <p class="mt-2">No se encontraron items</p>
                                <p class="text-sm">Intenta ajustar los filtros</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        
        {{-- Paginación --}}
        <div class="px-4 py-3 bg-gray-50 border-t">
            {{ $items->links() }}
        </div>
    </div>
    
    {{-- Loading overlay --}}
    <div wire:loading class="fixed inset-0 bg-gray-900 bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6">
            <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
            <p class="mt-4 text-gray-700">Cargando...</p>
        </div>
    </div>
</div>
```

### Rutas

```php
// routes/web.php (ya existe, verificar)
Route::middleware(['auth'])->group(function () {
    Route::get('/items', [ItemController::class, 'index'])->name('items.index');
    Route::get('/items/create', [ItemController::class, 'create'])->name('items.create');
    Route::get('/items/{item}/edit', [ItemController::class, 'edit'])->name('items.edit');
});
```

### Permisos

```php
// Verificar en database/seeders/PermissionSeeder.php
'items.view'   // Ver listado
'items.create' // Crear nuevo
'items.edit'   // Editar
'items.delete' // Eliminar
```

---

## ✅ CRITERIOS DE ACEPTACIÓN

### Funcionales
- [ ] Búsqueda por nombre/código funciona en tiempo real (debounce 300ms)
- [ ] Filtro por categoría filtra correctamente
- [ ] Filtro por estado (activo/inactivo) funciona
- [ ] Botón "Limpiar filtros" resetea todos los campos
- [ ] Tabla muestra 20 items por página
- [ ] Paginación funciona correctamente
- [ ] Click en columnas ordena ascendente/descendente
- [ ] Badge rojo cuando stock < stock_min
- [ ] Botón "Nuevo Item" redirige a creación
- [ ] Botones editar/eliminar funcionan
- [ ] Mensaje "No se encontraron items" cuando aplica

### No Funcionales
- [ ] UI responsive (funciona en móviles)
- [ ] Loading state mientras carga datos
- [ ] Sin queries N+1 (usar `with()`)
- [ ] Código sigue PSR-12
- [ ] Componentes reutilizables (Tailwind classes)
- [ ] Sin errores de consola JS

### UX
- [ ] Diseño consistente con resto de la app
- [ ] Colores según design system (azul primario, rojo alertas)
- [ ] Hover effects en botones y filas
- [ ] Iconos claros y reconocibles
- [ ] Feedback visual inmediato en acciones

---

## 📦 ENTREGABLES ESPERADOS

### Archivos a Crear

```
CREAR:
- app/Http/Livewire/Items/ItemList.php
- resources/views/livewire/items/item-list.blade.php

MODIFICAR (si necesario):
- resources/views/items/index.blade.php (incluir componente Livewire)
- routes/web.php (verificar rutas existen)
```

### Ejemplo de index.blade.php Modificado

```blade
{{-- resources/views/items/index.blade.php --}}
<x-app-layout>
    <x-slot name="header">
        <div class="flex items-center justify-between">
            <h2 class="text-2xl font-semibold text-gray-800">
                Inventario - Items
            </h2>
        </div>
    </x-slot>

    <div class="py-6">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            @livewire('items.item-list')
        </div>
    </div>
</x-app-layout>
```

---

## 🔍 VALIDACIÓN Y QUALITY CHECKS

### Antes de Entregar, Verifica:

#### Código
- [ ] `./vendor/bin/pint --test` pasa sin errores
- [ ] Visita `http://localhost:8000/items` y funciona
- [ ] Prueba cada filtro individualmente
- [ ] Prueba combinación de filtros
- [ ] Prueba ordenamiento de columnas
- [ ] Prueba paginación (navegar entre páginas)

#### Performance
- [ ] Query principal < 100ms
- [ ] Sin queries N+1 (verificar con Debugbar si está instalado)
- [ ] Loading rápido incluso con 100+ items

#### Responsive
- [ ] Abre en móvil (ancho <768px) y verifica usabilidad
- [ ] Tabla scrolleable horizontalmente en móviles
- [ ] Filtros apilados verticalmente en móviles

---

## 🎨 GUÍAS DE ESTILO

### Colores del Design System

```css
/* Primarios */
Azul principal: #2563eb (blue-600)
Azul hover: #1d4ed8 (blue-700)

/* Alertas */
Rojo: #dc2626 (red-600)
Amarillo: #f59e0b (amber-500)
Verde: #059669 (green-600)

/* Neutrales */
Gris claro: #f3f4f6 (gray-100)
Gris medio: #6b7280 (gray-500)
Gris oscuro: #1f2937 (gray-800)
```

### Componentes Reutilizables

- **Botones**: Siempre usar `px-4 py-2 rounded-md` + colores según acción
- **Badges**: Usar `px-2 py-1 rounded-full text-xs font-semibold`
- **Cards**: `bg-white rounded-lg shadow`
- **Inputs**: `rounded-md border-gray-300 shadow-sm`

---

## 📚 REFERENCIAS Y EJEMPLOS

### Código Similar en el Proyecto

```
✅ Ver componentes existentes:
- resources/views/livewire/cash-fund/cash-fund-list.blade.php
  (ejemplo de listado con filtros)
  
- app/Http/Livewire/CashFund/CashFundList.php
  (ejemplo de componente Livewire con paginación)
  
- resources/views/components/table.blade.php
  (componente de tabla reutilizable)
```

### Benchmarks

Ver `docs/UI-UX/MASTER/06_BENCHMARKS/Odoo.md` para inspiración de:
- Filtros avanzados
- Indicadores visuales
- Acciones rápidas

---

## 🚨 RESTRICCIONES Y WARNINGS

### ❌ NO HACER
- No usar jQuery (usar Alpine.js o Livewire)
- No hardcodear permisos en vistas (usar `@can()`)
- No usar queries N+1 (siempre `with()`)
- No cambiar schema BD sin migración

### ✅ SIEMPRE HACER
- Eager load relaciones: `with(['category', 'unit'])`
- Validar permisos: `@can('items.view')`
- Usar wire:loading para feedback visual
- Sanitizar búsqueda: SQL injection prevention (Eloquent lo hace)

---

## 💡 TIPS DE EFICIENCIA

1. **Copia el componente CashFundList** como base y adapta
2. **Reutiliza clases Tailwind** existentes en otros listados
3. **Usa Livewire's defer**: `wire:model.live` para filtros, no `wire:model.defer`
4. **Testea con datos reales**: Seed 100+ items para ver performance

---

## ✅ CHECKLIST FINAL

- [ ] Componente Livewire creado y funcionando
- [ ] Vista Blade renderiza correctamente
- [ ] Todos los filtros funcionan
- [ ] Paginación funciona
- [ ] Ordenamiento funciona
- [ ] Responsive en móviles
- [ ] Loading states implementados
- [ ] Sin errores de consola
- [ ] PSR-12 compliance
- [ ] Código comentado donde necesario

---

## 🎉 SIGUIENTE PASO

Una vez completada esta tarea:
1. **Commitea**: `git add . && git commit -m "feat(inventory): improved items list with filters and pagination" && git push`
2. **Notifica**: "✅ Tarea completada - Items list mejorado con filtros, paginación y UX"
3. **Siguiente**: Implementar formulario de creación/edición de items

---

**¡Éxito! 🚀**
```

---

## 📝 NOTAS PARA EL HUMANO (TÚ)

### Cómo Validar Esta Tarea

1. **Funcionalidad Básica**:
   ```bash
   php artisan serve
   # Visita http://localhost:8000/items
   # Prueba cada filtro
   # Verifica paginación
   # Intenta ordenar columnas
   ```

2. **Código**:
   ```bash
   ./vendor/bin/pint --test
   ```

3. **Performance**:
   ```bash
   php artisan tinker
   # User::factory(100)->create();
   # Item::factory(200)->create();
   # Verifica que listado cargue rápido
   ```

4. **Responsive**:
   - Abre DevTools
   - Toggle device toolbar
   - Prueba en iPhone SE, iPad, Desktop

### Tiempo Estimado de Validación
- ⏱️ 15-20 minutos

### Si Algo Falla
- Revisa logs: `storage/logs/laravel.log`
- Verifica rutas: `php artisan route:list | grep items`
- Verifica Livewire: `php artisan livewire:list`

---

**Éxito con la delegación! 🎯**
