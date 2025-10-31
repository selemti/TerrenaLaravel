# 📦 PAQUETE DE PROMPT - INVENTARIO

**Módulo**: Inventario  
**Componente**: Items/Altas  
**Versión**: 1.0  
**Fecha**: 31 de octubre de 2025

---

## 🎯 OBJETIVO

Implementar el wizard de alta de ítems en 2 pasos con validación inline y UX mejorada.

---

## 📋 PROMPT COMPLETO

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

### Estructura de Carpetas
```
app/
├── Http/
│   ├── Controllers/        # Controladores web y API
│   └── Livewire/          # Componentes Livewire
├── Models/                # Eloquent models
├── Services/              # Lógica de negocio
├── Jobs/                  # Async jobs
├── Events/                # Sistema de eventos
└── Console/               # Artisan commands

resources/
├── views/
│   ├── livewire/         # Vistas Livewire
│   ├── components/       # Blade components reutilizables
│   └── layouts/          # Layouts principales
└── js/                   # Alpine.js, helpers

database/
├── migrations/           # Schema changes
├── seeders/             # Data population
└── factories/            # Testing factories

docs/UI-UX/MASTER/        # 📚 DOCUMENTACIÓN PRINCIPAL
```

---

## 📊 ESTADO ACTUAL DEL PROYECTO

### Completitud General
| Área | Progreso | Estado |
|------|----------|--------|
| Base de Datos | 90% | ✅ Normalizada (Phases 2.1-2.4) |
| Backend Services | 70% | ⚠️ Core completo, falta refinamiento |
| API REST | 75% | ⚠️ Endpoints principales OK |
| Frontend Livewire | 60% | ⚠️ Funcional, falta UX polish |
| Design System | 20% | 🔴 Por implementar |
| Testing | 30% | 🔴 Cobertura baja |

### Módulo Inventario
| Componente | Backend | Frontend | Estado |
|------------|---------|----------|--------|
| Items/Altas | 70% | 60% | ⚠️ Bueno |
| Recepciones | 75% | 70% | ⚠️ Bueno |
| Lotes/Caducidades | 65% | 60% | ⚠️ Regular |
| Conteos | 85% | 80% | ✅ Muy Bueno |
| Transferencias | 50% | 45% | 🔴 Crítico |

---

## 📚 DOCUMENTACIÓN DISPONIBLE

**CRÍTICO**: Consulta estos documentos antes de iniciar cualquier tarea:

### Navegación Principal
📂 `docs/UI-UX/MASTER/README.md` - Índice maestro de toda la documentación

### Por Tipo de Tarea

#### Para Backend
- `01_ESTADO_PROYECTO/01_BACKEND_STATUS.md` - Inventario completo backend
- `02_MODULOS/Inventario.md` - Specs del módulo específico
- `03_ARQUITECTURA/04_DATABASE_SCHEMA.md` - Schema BD consolidado
- `05_SPECS_TECNICAS/SERVICIOS_BACKEND.md` - Patrones de servicios
- `05_SPECS_TECNICAS/API_ENDPOINTS.md` - Convenciones API

#### Para Frontend
- `01_ESTADO_PROYECTO/02_FRONTEND_STATUS.md` - Inventario completo frontend
- `03_ARQUITECTURA/02_DESIGN_SYSTEM.md` - Componentes UI/UX
- `05_SPECS_TECNICAS/COMPONENTES_LIVEWIRE.md` - Patrones Livewire
- `05_SPECS_TECNICAS/COMPONENTES_BLADE.md` - Blade components

#### Para BD
- `docs/BD/Normalizacion/PROYECTO_100_COMPLETADO.md` - Estado normalización BD
- `03_ARQUITECTURA/04_DATABASE_SCHEMA.md` - Schema actualizado

#### Referencias de Calidad
- `06_BENCHMARKS/` - Cómo lo hacen Oracle, Odoo, SAP, Toast, Square
- `08_RECURSOS/DECISIONES.md` - Log de decisiones técnicas

---

## 🎯 TAREA ESPECÍFICA

### Módulo: Inventario
**Componente**: Items/Altas

### Descripción de la Tarea
**Crear wizard de alta de ítems en 2 pasos con validación inline y UX mejorada**

El wizard debe:
1. Paso 1: Datos maestros (nombre, categoría, UOM base)
2. Paso 2: Presentaciones/Proveedor (opcional)
3. Validación inline por campo con mensajes específicos
4. Preview de código CAT-SUB-##### antes de guardar
5. Botón "Crear y seguir con presentaciones"
6. Autosuggest de nombres normalizados

### Contexto Adicional
Actualmente existe un formulario básico en `/inventory/items/new` pero:
- Falta validación inline con mensajes específicos
- No hay preview del código antes de guardar
- No hay wizard en 2 pasos
- La validación es genérica ("No se pudo guardar el insumo...")

---

## 📋 ESPECIFICACIONES TÉCNICAS

### Modelos Involucrados
```php
- App\Models\Item (selemti.items)
- App\Models\Catalogs\Unidad (selemti.cat_unidades)
- App\Models\Catalogs\Category (selemti.categories)
- App\Models\Inv\ItemVendor (selemti.item_vendor)
- App\Models\Inv\ItemVendorPrice (selemti.item_vendor_prices)
```

### Rutas/Endpoints
```php
// Web Routes
Route::get('/inventory/items/new', [Inventory\InsumoCreate::class, 'create'])->name('inventory.items.new');
Route::post('/inventory/items', [Inventory\InsumoCreate::class, 'store'])->name('inventory.items.store');

// API Routes
Route::prefix('inventory')->group(function () {
    Route::prefix('items')->group(function () {
        Route::get('/', [ItemController::class, 'index']);
        Route::get('/{id}', [ItemController::class, 'show']);
        Route::post('/', [ItemController::class, 'store']);
        Route::put('/{id}', [ItemController::class, 'update']);
        Route::delete('/{id}', [ItemController::class, 'destroy']);
    });
});
```

### Validaciones
```php
[
    'nombre' => 'required|string|max:120|unique:selemti.items,nombre',
    'categoria_id' => 'required|exists:selemti.categories,id',
    'unidad_medida_id' => 'required|exists:selemti.cat_unidades,id',
    'unidad_compra_id' => 'nullable|exists:selemti.cat_unidades,id',
    'unidad_salida_id' => 'nullable|exists:selemti.cat_unidades,id',
    'activo' => 'nullable|boolean',
    'perecible' => 'nullable|boolean',
    'factor_conversion' => 'nullable|numeric|min:0.000001',
    'factor_compra' => 'nullable|numeric|min:0.000001',
    'codigo_proveedor' => 'nullable|string|max:64',
    'sku_proveedor' => 'nullable|string|max:64',
    'presentacion_proveedor' => 'nullable|string|max:120',
]
```

### Permisos
```php
- 'inventory.items.view' - Ver catálogo de ítems
- 'inventory.items.manage' - Crear/Editar ítems
- 'inventory.uoms.view' - Ver presentaciones
- 'inventory.uoms.manage' - Gestionar presentaciones
```

### Base de Datos
```sql
-- Tabla items
CREATE TABLE selemti.items (
    id VARCHAR(64) PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    categoria_id VARCHAR(64),
    unidad_medida_id INTEGER,
    unidad_compra_id INTEGER,
    unidad_salida_id INTEGER,
    activo BOOLEAN DEFAULT true,
    perecible BOOLEAN DEFAULT false,
    factor_conversion NUMERIC(18,6),
    factor_compra NUMERIC(18,6),
    costo_promedio NUMERIC(18,4),
    meta JSONB,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Tabla item_vendor
CREATE TABLE selemti.item_vendor (
    id BIGSERIAL PRIMARY KEY,
    item_id VARCHAR(64) NOT NULL REFERENCES selemti.items(id),
    vendor_id BIGINT NOT NULL REFERENCES selemti.cat_proveedores(id),
    presentacion VARCHAR(120),
    unidad_presentacion_id INTEGER REFERENCES selemti.cat_unidades(id),
    factor_a_canonica NUMERIC(18,6),
    costo_ultimo NUMERIC(14,4),
    moneda VARCHAR(3) DEFAULT 'MXN',
    lead_time_dias INTEGER DEFAULT 3,
    codigo_proveedor VARCHAR(64),
    sku_proveedor VARCHAR(64),
    activo BOOLEAN DEFAULT true,
    preferente BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla item_vendor_prices
CREATE TABLE selemti.item_vendor_prices (
    id BIGSERIAL PRIMARY KEY,
    item_id VARCHAR(64) NOT NULL REFERENCES selemti.items(id),
    vendor_id BIGINT NOT NULL REFERENCES selemti.cat_proveedores(id),
    precio NUMERIC(14,4) NOT NULL,
    pack_qty NUMERIC(16,4) NOT NULL,
    pack_uom VARCHAR(20) NOT NULL,
    effective_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    effective_to TIMESTAMP WITH TIME ZONE,
    source VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## ✅ CRITERIOS DE ACEPTACIÓN

### Funcionales
- [ ] Wizard de alta en 2 pasos funcionando
- [ ] Paso 1: Datos maestros con validación inline
- [ ] Paso 2: Presentaciones/Proveedor opcional
- [ ] Preview de código CAT-SUB-##### antes de guardar
- [ ] Botón "Crear y seguir con presentaciones"
- [ ] Autosuggest de nombres normalizados
- [ ] Validación inline con mensajes específicos
- [ ] Generación automática de código único
- [ ] Asociación automática con UOM base
- [ ] Relaciones con categorías existentes

### No Funcionales
- [ ] Código sigue PSR-12 (PHP) o estándares del proyecto
- [ ] Componentes reutilizables (DRY principle)
- [ ] Queries optimizadas (eager loading, índices)
- [ ] Transacciones DB para operaciones críticas
- [ ] Manejo de errores completo (try-catch, logs)
- [ ] Comentarios solo donde sea necesario (código auto-explicativo)

### Testing (si aplica)
- [ ] Tests unitarios para servicios/lógica de negocio
- [ ] Tests de integración para controllers/API
- [ ] Tests de validación para FormRequests

---

## 📦 ENTREGABLES ESPERADOS

### Archivos a Crear/Modificar
```markdown
CREAR:
- app/Http/Livewire/Inventory/ItemWizard.php
- resources/views/livewire/inventory/item-wizard.blade.php
- app/Http/Requests/Inventory/StoreItemRequest.php
- app/Http/Requests/Inventory/UpdateItemRequest.php

MODIFICAR:
- app/Http/Controllers/Inventory/InsumoCreate.php
- resources/views/livewire/inventory/insumo-create.blade.php
- routes/web.php (agregar ruta wizard)
- database/seeders/PermissionSeeder.php (verificar permisos)
```

### Documentación
- [ ] Comentarios PHPDoc en clases y métodos públicos
- [ ] README del módulo actualizado (si aplica)
- [ ] Changelog de cambios importantes

---

## 🔍 VALIDACIÓN Y QUALITY CHECKS

### Antes de Entregar, Verifica:

#### Código
- [ ] PSR-12 compliance: `./vendor/bin/pint --test`
- [ ] No errores: `php artisan optimize && php artisan cache:clear`
- [ ] Rutas funcionan: `php artisan route:list | grep {modulo}`

#### Base de Datos
- [ ] Migraciones OK: `php artisan migrate:fresh --seed` sin errores
- [ ] Relaciones correctas: Probar consultas Eloquent

#### Frontend (si aplica)
- [ ] Vistas renderizan: Probar en navegador
- [ ] Livewire funciona: `php artisan livewire:list`
- [ ] Assets compilados: `npm run build` sin errores

#### Testing
- [ ] Tests pasan: `php artisan test --filter={TestName}`
- [ ] Cobertura >80% (ideal)

---

## 🎨 GUÍAS DE ESTILO

### PHP (Backend)
```php
<?php

namespace App\Http\Livewire\Inventory;

use Livewire\Component;
use App\Models\Item;
use App\Models\Catalogs\Category;
use App\Models\Catalogs\Unidad;
use App\Http\Requests\Inventory\StoreItemRequest;

class ItemWizard extends Component
{
    public $step = 1;
    public $item = [];
    public $presentations = [];
    
    protected $rules = [
        'item.nombre' => 'required|string|max:120|unique:selemti.items,nombre',
        'item.categoria_id' => 'required|exists:selemti.categories,id',
        'item.unidad_medida_id' => 'required|exists:selemti.cat_unidades,id',
        // ... otras reglas
    ];

    public function nextStep()
    {
        $this->validateOnly('item.nombre');
        $this->validateOnly('item.categoria_id');
        $this->validateOnly('item.unidad_medida_id');
        
        $this->step++;
    }

    public function previousStep()
    {
        $this->step--;
    }

    public function createItem()
    {
        $validatedData = $this->validate();
        
        // Crear item usando transacción
        DB::transaction(function () use ($validatedData) {
            $item = Item::create($validatedData['item']);
            
            // Si hay presentaciones, crear relaciones
            if (!empty($validatedData['presentations'])) {
                foreach ($validatedData['presentations'] as $presentation) {
                    $item->vendors()->create($presentation);
                }
            }
            
            return $item;
        });
        
        $this->dispatch('toast', type: 'success', body: 'Ítem creado exitosamente');
        return redirect()->route('inventory.items.index');
    }

    public function render()
    {
        return view('livewire.inventory.item-wizard', [
            'categories' => Category::orderBy('name')->get(),
            'units' => Unidad::orderBy('nombre')->get(),
        ]);
    }
}
```

### Blade (Frontend)
```blade
<x-app-layout>
    <x-slot name="header">
        <h2 class="text-xl font-semibold">Nuevo Ítem - Wizard</h2>
    </x-slot>

    <div class="py-6">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="bg-white rounded-lg shadow p-6">
                <!-- Paso 1: Datos Maestros -->
                @if($step == 1)
                    <div>
                        <h3 class="text-lg font-medium mb-4">Datos Maestros</h3>
                        
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label class="block text-sm font-medium text-gray-700">Nombre *</label>
                                <input type="text" 
                                       wire:model.live="item.nombre"
                                       class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                @error('item.nombre') 
                                    <span class="text-red-600 text-sm">{{ $message }}</span> 
                                @enderror
                            </div>
                            
                            <div>
                                <label class="block text-sm font-medium text-gray-700">Categoría *</label>
                                <select wire:model.live="item.categoria_id"
                                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                    <option value="">Seleccione...</option>
                                    @foreach($categories as $category)
                                        <option value="{{ $category->id }}">{{ $category->name }}</option>
                                    @endforeach
                                </select>
                                @error('item.categoria_id') 
                                    <span class="text-red-600 text-sm">{{ $message }}</span> 
                                @enderror
                            </div>
                            
                            <!-- Más campos... -->
                        </div>
                        
                        <div class="mt-6 flex justify-between">
                            <div></div>
                            <button wire:click="nextStep"
                                    class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
                                Siguiente
                            </button>
                        </div>
                    </div>
                @endif
                
                <!-- Paso 2: Presentaciones/Proveedor -->
                @if($step == 2)
                    <div>
                        <h3 class="text-lg font-medium mb-4">Presentaciones y Proveedor (Opcional)</h3>
                        
                        <!-- Formulario de presentaciones... -->
                        
                        <div class="mt-6 flex justify-between">
                            <button wire:click="previousStep"
                                    class="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400">
                                Anterior
                            </button>
                            <button wire:click="createItem"
                                    class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700">
                                Crear Ítem
                            </button>
                        </div>
                    </div>
                @endif
            </div>
        </div>
    </div>
</x-app-layout>
```

### Livewire Component
```php
<?php

namespace App\Http\Livewire\Inventory;

use Livewire\Component;
use App\Models\Item;
use Illuminate\Support\Facades\DB;

class ItemWizard extends Component
{
    public $step = 1;
    public $item = [];
    public $presentations = [];
    
    public function mount()
    {
        $this->item = [
            'activo' => true,
            'perecible' => false,
        ];
    }
    
    public function nextStep()
    {
        // Validación inline del paso actual
        $this->validateCurrentStep();
        $this->step++;
    }
    
    public function previousStep()
    {
        $this->step--;
    }
    
    public function createItem()
    {
        // Validación completa antes de guardar
        $validatedData = $this->validate();
        
        DB::transaction(function () use ($validatedData) {
            // Crear ítem
            $item = Item::create($validatedData['item']);
            
            // Crear presentaciones si existen
            if (!empty($validatedData['presentations'])) {
                foreach ($validatedData['presentations'] as $presentation) {
                    $item->vendors()->create($presentation);
                }
            }
        });
        
        $this->dispatch('toast', type: 'success', body: 'Ítem creado exitosamente');
        return redirect()->route('inventory.items.index');
    }
    
    protected function validateCurrentStep()
    {
        if ($this->step === 1) {
            $this->validateOnly('item.nombre');
            $this->validateOnly('item.categoria_id');
            $this->validateOnly('item.unidad_medida_id');
        }
    }
    
    public function render()
    {
        return view('livewire.inventory.item-wizard')
            ->layout('layouts.terrena', [
                'active' => 'inventario',
                'title' => 'Nuevo Ítem · Inventario',
            ]);
    }
}
```

---

## 📚 REFERENCIAS Y EJEMPLOS

### Código Similar en el Proyecto
```markdown
- Ver `app/Http/Livewire/Inventory/InsumoCreate.php` - Patrón de creación de ítems
- Ver `app/Http/Controllers/Inventory/InsumoController.php` - Estructura de controllers
- Ver `resources/views/livewire/inventory/insumo-create.blade.php` - Layout base para formularios
- Ver `app/Services/Inventory/InsumoCodeService.php` - Generación de códigos
```

### Documentación Externa
- [Laravel 11 Docs](https://laravel.com/docs/11.x)
- [Livewire 3 Docs](https://livewire.laravel.com/docs)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [Spatie Laravel Permission](https://spatie.be/docs/laravel-permission)

---

## 🚨 RESTRICCIONES Y WARNINGS

### ❌ NO HACER
- **No eliminar código funcional** sin confirmar
- **No cambiar schema BD** sin migración
- **No usar relaciones N+1** (usar `with()`)
- **No hardcodear valores** (usar config o .env)
- **No exponer datos sensibles** en logs o API
- **No usar jQuery** (usar Alpine.js)

### ✅ SIEMPRE HACER
- **Usar transacciones DB** para operaciones multi-tabla
- **Validar permisos** en controllers
- **Sanitizar inputs** (FormRequests)
- **Manejar errores** con try-catch
- **Eager load** relaciones cuando sea posible
- **Seguir convenciones** del proyecto existente

---

## 💡 TIPS DE EFICIENCIA

### Para IAs Trabajando en Este Proyecto

1. **Lee primero**: `MASTER/README.md` y el módulo específico en `02_MODULOS/Inventario.md`
2. **Busca ejemplos**: Siempre hay código similar que puedes adaptar
3. **Usa el schema**: `03_ARQUITECTURA/04_DATABASE_SCHEMA.md` para relaciones
4. **Sigue patrones**: No inventes, usa lo que ya existe
5. **Pregunta si hay dudas**: Mejor clarificar que asumir mal

### Debugging Común
- **Errores de FKs**: Verifica que `03_ARQUITECTURA/04_DATABASE_SCHEMA.md` esté actualizado
- **Livewire no reactivo**: Propiedades públicas mal definidas
- **Permisos denegados**: Verificar en `database/seeders/PermissionSeeder.php`

---

## 📞 SOPORTE Y ESCALACIÓN

### Si Te Atoras
1. **Revisa documentación MASTER**: 90% de las dudas están ahí
2. **Busca código similar**: `grep -r "item" app/`
3. **Consulta benchmarks**: `06_BENCHMARKS/` para mejores prácticas
4. **Pregunta al humano**: Si después de 30 min sigues atorado

### Reportar Problemas
Si encuentras inconsistencias en la documentación o código legacy problemático:
```markdown
## 🐛 Issue Encontrado

**Ubicación**: {archivo y línea}
**Problema**: {descripción}
**Impacto**: {cómo afecta la tarea actual}
**Sugerencia**: {cómo resolverlo}
```

---

## ✅ CHECKLIST FINAL ANTES DE ENTREGAR

- [ ] Código funciona localmente (probado manualmente)
- [ ] Linter OK (`./vendor/bin/pint`)
- [ ] Tests pasan (`php artisan test`)
- [ ] Migraciones aplicadas sin errores
- [ ] Permisos seedeados si es necesario
- [ ] Documentación actualizada
- [ ] Commits con mensaje descriptivo
- [ ] Sin TODOs o FIXMEs pendientes críticos
- [ ] Variables de entorno documentadas (si aplica)
- [ ] Performance aceptable (consultas <100ms idealmente)

---

## 🎉 SIGUIENTE PASO

Una vez completada esta tarea:
1. **Pushea tus cambios**: `git add . && git commit -m "feat(inventory): add item wizard with 2-step process" && git push`
2. **Notifica completitud**: Incluye resumen de archivos modificados
3. **Prepárate para revisión**: El humano validará con `CHECKLIST_VALIDACION.md`

---

**¡Éxito con la implementación! 🚀**