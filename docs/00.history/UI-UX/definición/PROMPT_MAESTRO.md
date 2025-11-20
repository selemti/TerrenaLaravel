# PROMPT MAESTRO PARA DELEGACIÓN A IAS

**Versión**: 1.0  
**Fecha**: 31 de octubre de 2025  
**Proyecto**: TerrenaLaravel ERP  
**Propósito**: Template universal para delegar tareas de desarrollo a IAs

---

## 📋 CÓMO USAR ESTE PROMPT

### Estructura del Prompt Maestro

```markdown
[CONTEXTO_DEL_PROYECTO]
  ↓
[ARQUITECTURA_Y_TECNOLOGÍAS]
  ↓
[ESTADO_ACTUAL_Y_DOCUMENTACIÓN]
  ↓
[TAREA_ESPECÍFICA]
  ↓
[CRITERIOS_DE_ACEPTACIÓN]
  ↓
[VALIDACIÓN_Y_ENTREGABLES]
```

### Para Usar:
1. **Copia la sección**: PROMPT COMPLETO (más abajo)
2. **Reemplaza variables**: `{VARIABLE}` con valores específicos
3. **Adjunta docs relevantes**: De `docs/UI-UX/definición/` según el módulo
4. **Ejecuta con la IA**: Claude, Qwen, ChatGPT, etc.
5. **Valida resultado**: Con CHECKLIST_VALIDACION.md

---

## 🎯 PROMPT COMPLETO (COPIAR Y PERSONALIZAR)

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
**Stack**: Laravel 12, Livewire 3, Alpine.js, Tailwind CSS, PostgreSQL 9.5

---

## 🏗️ ARQUITECTURA Y TECNOLOGÍAS

### Backend
- **Framework**: Laravel 12 (PHP 8.2+)
- **Database**: PostgreSQL 9.5 (esquema `selemti`)
- **ORM**: Eloquent
- **Autenticación**: Laravel Breeze + Spatie Permissions
- **Jobs/Queues**: Redis (async processing)
- **API**: RESTful (routes/api.php)

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
│   ├── components/       # Blade components
│   └── layouts/          # Layouts principales
└── js/                   # Alpine.js, helpers

database/
├── migrations/           # Schema changes
├── seeders/             # Data population
└── factories/           # Testing factories

docs/
└── UI-UX/
    └── MASTER/          # 📚 DOCUMENTACIÓN PRINCIPAL
```

---

## 📊 ESTADO ACTUAL DEL PROYECTO

### Completitud General
| Área | Progreso | Estado |
|------|----------|--------|
| Base de Datos | 90% | ✅ Normalizada (Phases 2.1-2.4) |
| Backend Services | 65% | 🟡 Core completo, falta refinamiento |
| API REST | 75% | 🟡 Endpoints principales OK |
| Frontend Livewire | 60% | 🟡 Funcional, falta UX polish |
| Design System | 20% | 🔴 Por implementar |
| Testing | 30% | 🔴 Cobertura baja |

### Módulos por Estado
| Módulo | Backend | Frontend | Prioridad |
|--------|---------|----------|-----------|
| Inventario | 70% | 70% | 🔴 CRÍTICO |
| Compras | 60% | 60% | 🔴 CRÍTICO |
| Recetas | 50% | 50% | 🟡 ALTO |
| Producción | 30% | 30% | 🟡 ALTO |
| Caja Chica | 80% | 80% | 🟢 BAJO (casi completo) |
| Reportes | 40% | 40% | 🟡 ALTO |
| Catálogos | 80% | 80% | 🟢 BAJO (casi completo) |
| Permisos | 80% | 80% | 🟢 BAJO (funcional) |

### Trabajos Recientes Completados
- ✅ **Phase 2.1**: Consolidación usuarios y roles (users/roles tables)
- ✅ **Phase 2.2**: Consolidación sucursales y almacenes (branches/warehouses)
- ✅ **Phase 2.3**: Consolidación items (products unificados)
- ✅ **Phase 2.4**: Consolidación recetas (recipes versionadas)
- ✅ **Fase 3**: Mejora integridad referencial (FKs, constraints)
- ✅ **Fase 4**: Optimización performance (índices, queries)
- ✅ **Fase 5**: Features enterprise (auditoría, soft deletes)

**Próximas Fases**:
- ⏳ Fase 2: Design System & UI Components
- ⏳ Fase 3: Inventario Sólido (CRUD completo + UX)
- ⏳ Fase 4: Motor Reposición (automatización compras)

---

## 📚 DOCUMENTACIÓN DISPONIBLE

**CRÍTICO**: Consulta estos documentos antes de iniciar cualquier tarea:

### Navegación Principal
📂 `docs/UI-UX/MASTER/README.md` - Índice maestro de toda la documentación

### Por Tipo de Tarea

#### Para Backend
- `01_ESTADO_PROYECTO/01_BACKEND_STATUS.md` - Inventario completo backend
- `02_MODULOS/{MODULO}.md` - Specs del módulo específico
- `03_ARQUITECTURA/04_DATABASE_SCHEMA.md` - Schema BD consolidado
- `05_SPECS_TECNICAS/SERVICIOS_BACKEND.md` - Patrones de servicios
- `05_SPECS_TECNICAS/API_ENDPOINTS.md` - Convenciones API

#### Para Frontend
- `01_ESTADO_PROYECTO/02_FRONTEND_STATUS.md` - Inventario completo frontend
- `03_ARQUITECTURA/02_DESIGN_SYSTEM.md` - Componentes UI/UX
- `05_SPECS_TECNICAS/COMPONENTES_LIVEWIRE.md` - Patrones Livewire
- `05_SPECS_TECNICAS/COMPONENTES_BLADE.md` - Blade components

#### Para BD
- `docs/BD/Normalizacion/PROYECTO_100_COMPLETADO.md` - Estado normalización
- `03_ARQUITECTURA/04_DATABASE_SCHEMA.md` - Schema actualizado

#### Referencias de Calidad
- `06_BENCHMARKS/` - Cómo lo hacen Oracle, Odoo, SAP, Toast, Square
- `08_RECURSOS/DECISIONES.md` - Log de decisiones técnicas

---

## 🎯 TAREA ESPECÍFICA

### Módulo: `{MODULO}`
**Ejemplo**: Inventario, Compras, Recetas, etc.

### Componente: `{COMPONENTE}`
**Ejemplo**: ItemsService, InventoryController, inventory-list.blade.php, etc.

### Descripción de la Tarea
**{DESCRIPCION_TAREA}**

**Ejemplo**:
```markdown
Crear el servicio `TransferService` que maneje transferencias de inventario entre almacenes.
Debe incluir:
- Validación de stock disponible
- Creación de transacción (transfer_header + transfer_details)
- Actualización de stock en ambos almacenes
- Generación de eventos para auditoría
- Manejo de errores y rollback
```

### Contexto Adicional
**{CONTEXTO_NEGOCIO}**

**Ejemplo**:
```markdown
Las transferencias son críticas para operaciones multi-almacén.
Deben ser atómicas (todo o nada) y auditables.
El usuario debe poder:
- Seleccionar almacén origen/destino
- Agregar múltiples items con cantidades
- Aprobar/rechazar la transferencia
- Ver historial de transferencias
```

---

## 📋 ESPECIFICACIONES TÉCNICAS

### Modelos Involucrados
**{MODELOS}**

**Ejemplo**:
```php
- TransferHeader (transfer_header table)
- TransferDetail (transfer_detail table)
- Item (items table)
- Warehouse (warehouses table)
- User (users table) - para auditoría
```

### Rutas/Endpoints
**{RUTAS}**

**Ejemplo**:
```php
// Web Routes
Route::group(['prefix' => 'transfers'], function() {
    Route::get('/', [TransferController::class, 'index'])->name('transfers.index');
    Route::get('/create', [TransferController::class, 'create'])->name('transfers.create');
    Route::post('/', [TransferController::class, 'store'])->name('transfers.store');
});

// API Routes
Route::apiResource('transfers', TransferApiController::class);
```

### Validaciones
**{VALIDACIONES}**

**Ejemplo**:
```php
- warehouse_from_id: required, exists:warehouses,id
- warehouse_to_id: required, exists:warehouses,id, different:warehouse_from_id
- items: required, array, min:1
- items.*.item_id: required, exists:items,id
- items.*.quantity: required, numeric, min:0.01
- Stock disponible >= cantidad solicitada (regla custom)
```

### Permisos
**{PERMISOS}**

**Ejemplo**:
```php
- 'transfers.view' - Ver listado
- 'transfers.create' - Crear nueva
- 'transfers.approve' - Aprobar
- 'transfers.delete' - Eliminar (soft delete)
```

### Base de Datos
**{TABLAS_BD}**

**Ejemplo**:
```sql
-- transfer_header
id, warehouse_from_id, warehouse_to_id, user_id, status, notes, created_at, updated_at

-- transfer_detail
id, transfer_header_id, item_id, quantity, unit_cost, total_cost

-- Relaciones:
- transfer_header.warehouse_from_id → warehouses.id
- transfer_header.warehouse_to_id → warehouses.id
- transfer_detail.item_id → items.id
```

---

## ✅ CRITERIOS DE ACEPTACIÓN

### Funcionales
- [ ] **{CRITERIOS_ACEPTACION}**

**Ejemplo**:
- [ ] Usuario puede crear transferencia entre 2 almacenes
- [ ] Sistema valida stock disponible antes de aprobar
- [ ] Stock se actualiza correctamente en ambos almacenes
- [ ] Eventos de auditoría se disparan correctamente
- [ ] Errores se manejan con mensajes claros al usuario

### No Funcionales
- [ ] **Código sigue PSR-12** (PHP) o estándares del proyecto
- [ ] **Componentes reutilizables** (DRY principle)
- [ ] **Queries optimizadas** (eager loading, índices)
- [ ] **Transacciones DB** para operaciones críticas
- [ ] **Manejo de errores** completo (try-catch, logs)
- [ ] **Comentarios** solo donde sea necesario (código auto-explicativo)

### Testing (si aplica)
- [ ] **Tests unitarios** para servicios/lógica de negocio
- [ ] **Tests de integración** para controllers/API
- [ ] **Tests de validación** para FormRequests

---

## 📦 ENTREGABLES ESPERADOS

### Archivos a Crear/Modificar
**{ARCHIVOS}**

**Ejemplo**:
```markdown
CREAR:
- app/Services/TransferService.php
- app/Http/Controllers/TransferController.php
- app/Http/Requests/StoreTransferRequest.php
- resources/views/transfers/index.blade.php
- resources/views/transfers/create.blade.php
- tests/Feature/TransferTest.php

MODIFICAR:
- routes/web.php (agregar rutas)
- database/seeders/PermissionSeeder.php (agregar permisos)
```

### Documentación
- [ ] **Comentarios PHPDoc** en clases y métodos públicos
- [ ] **README** del módulo actualizado (si aplica)
- [ ] **Changelog** de cambios importantes

---

## 🔍 VALIDACIÓN Y QUALITY CHECKS

### Antes de Entregar, Verifica:

#### Código
- [ ] **PSR-12 compliance**: `./vendor/bin/pint --test`
- [ ] **No errores**: `php artisan optimize && php artisan cache:clear`
- [ ] **Rutas funcionan**: `php artisan route:list | grep {modulo}`

#### Base de Datos
- [ ] **Migraciones OK**: `php artisan migrate:fresh --seed` sin errores
- [ ] **Relaciones correctas**: Probar consultas Eloquent

#### Frontend (si aplica)
- [ ] **Vistas renderizan**: Probar en navegador
- [ ] **Livewire funciona**: `php artisan livewire:list`
- [ ] **Assets compilados**: `npm run build` sin errores

#### Testing
- [ ] **Tests pasan**: `php artisan test --filter={TestName}`
- [ ] **Cobertura >80%** (ideal)

---

## 🎨 GUÍAS DE ESTILO

### PHP (Backend)
```php
<?php

namespace App\Services;

use App\Models\TransferHeader;
use Illuminate\Support\Facades\DB;

class TransferService
{
    /**
     * Crear nueva transferencia entre almacenes
     */
    public function createTransfer(array $data): TransferHeader
    {
        return DB::transaction(function () use ($data) {
            // Validar stock
            $this->validateStock($data);
            
            // Crear header
            $transfer = TransferHeader::create([
                'warehouse_from_id' => $data['warehouse_from_id'],
                'warehouse_to_id' => $data['warehouse_to_id'],
                'user_id' => auth()->id(),
                'status' => 'pending',
            ]);
            
            // Crear detalles
            foreach ($data['items'] as $item) {
                $transfer->details()->create($item);
            }
            
            return $transfer;
        });
    }
}
```

### Blade (Frontend)
```blade
<x-app-layout>
    <x-slot name="header">
        <h2 class="text-xl font-semibold">Transferencias</h2>
    </x-slot>

    <div class="py-6">
        <div class="max-w-7xl mx-auto px-4">
            <!-- Contenido -->
        </div>
    </div>
</x-app-layout>
```

### Livewire Component
```php
<?php

namespace App\Http\Livewire;

use Livewire\Component;

class TransferList extends Component
{
    public $transfers;
    
    public function mount()
    {
        $this->loadTransfers();
    }
    
    public function render()
    {
        return view('livewire.transfer-list');
    }
}
```

---

## 📚 REFERENCIAS Y EJEMPLOS

### Código Similar en el Proyecto
**{REFERENCIAS_INTERNAS}**

**Ejemplo**:
```markdown
- Ver `app/Services/CashFundService.php` - Patrón de servicios similar
- Ver `app/Http/Controllers/InventoryController.php` - Estructura de controllers
- Ver `resources/views/inventory/index.blade.php` - Layout base para listados
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

1. **Lee primero**: `MASTER/README.md` y el módulo específico en `02_MODULOS/{modulo}.md`
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
2. **Busca código similar**: `grep -r "palabra_clave" app/`
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
- [ ] Performance aceptable (queries <100ms idealmente)

---

## 🎉 SIGUIENTE PASO

Una vez completada esta tarea:
1. **Pushea tus cambios**: `git add . && git commit -m "feat({modulo}): {descripción}" && git push`
2. **Notifica completitud**: Incluye resumen de archivos modificados
3. **Prepárate para revisión**: El humano validará con `CHECKLIST_VALIDACION.md`

---

**¡Éxito con la implementación! 🚀**
```

---

## 🔄 VARIANTES DEL PROMPT

### Para Tareas de BACKEND
Incluir:
- `05_SPECS_TECNICAS/SERVICIOS_BACKEND.md`
- `05_SPECS_TECNICAS/API_ENDPOINTS.md`
- `03_ARQUITECTURA/04_DATABASE_SCHEMA.md`

### Para Tareas de FRONTEND
Incluir:
- `03_ARQUITECTURA/02_DESIGN_SYSTEM.md`
- `05_SPECS_TECNICAS/COMPONENTES_LIVEWIRE.md`
- `05_SPECS_TECNICAS/COMPONENTES_BLADE.md`

### Para Tareas de BASE DE DATOS
Incluir:
- `docs/BD/Normalizacion/PROYECTO_100_COMPLETADO.md`
- `03_ARQUITECTURA/04_DATABASE_SCHEMA.md`
- `05_SPECS_TECNICAS/MIGRACIONES_SEEDERS.md`

---

## 📝 EJEMPLO COMPLETO DE USO

Ver: `EJEMPLO_DELEGACION_INVENTARIO.md` (próximo documento)

---

**Creado por**: Equipo TerrenaLaravel  
**Última actualización**: 2025-10-31  
**Versión**: 1.0  
**Licencia**: Internal Use Only