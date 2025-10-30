# PERMISOS PARA CAJA CHICA

**Sistema de permisos:** Spatie Laravel Permission
**Fecha:** 2025-10-23

---

## 📋 PERMISOS REQUERIDOS

El módulo de Caja Chica requiere **2 permisos** para funcionar correctamente:

### 1. `approve-cash-funds`
**Descripción:** Permite aprobar y rechazar fondos en revisión

**Capacidades que otorga:**
- ✅ Acceder al módulo de Aprobaciones (`/cashfund/approvals`)
- ✅ Ver lista de fondos EN_REVISION
- ✅ Ver detalle completo de fondos
- ✅ Aprobar movimientos individuales sin comprobante
- ✅ Rechazar fondos (regresarlos a ABIERTO)

**Usuarios recomendados:**
- Supervisores
- Gerentes de área
- Administradores
- Cualquier usuario autorizado para revisar fondos

### 2. `close-cash-funds`
**Descripción:** Permite cerrar definitivamente fondos (EN_REVISION → CERRADO)

**Capacidades que otorga:**
- ✅ Cerrar definitivamente un fondo revisado
- ✅ Transición final de estado (no reversible)

**Usuarios recomendados:**
- Gerentes
- Administradores
- Contralores
- Personal de finanzas

---

## 🔧 INSTALACIÓN DE PERMISOS

### Opción 1: Usando Seeder (Recomendado)

Crear archivo: `database/seeders/CashFundPermissionsSeeder.php`

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;

class CashFundPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        // Crear permisos de Caja Chica
        $permissions = [
            [
                'name' => 'approve-cash-funds',
                'guard_name' => 'web',
                'description' => 'Aprobar y rechazar fondos de caja chica en revisión',
            ],
            [
                'name' => 'close-cash-funds',
                'guard_name' => 'web',
                'description' => 'Cerrar definitivamente fondos de caja chica',
            ],
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(
                ['name' => $permission['name'], 'guard_name' => $permission['guard_name']],
                $permission
            );
        }

        $this->command->info('✅ Permisos de Caja Chica creados correctamente');
    }
}
```

**Ejecutar:**
```bash
php artisan db:seed --class=CashFundPermissionsSeeder
```

### Opción 2: Usando Tinker

```bash
php artisan tinker
```

```php
use Spatie\Permission\Models\Permission;

// Crear permiso de aprobar
Permission::create([
    'name' => 'approve-cash-funds',
    'guard_name' => 'web',
]);

// Crear permiso de cerrar
Permission::create([
    'name' => 'close-cash-funds',
    'guard_name' => 'web',
]);
```

### Opción 3: SQL Directo (PostgreSQL)

```sql
INSERT INTO public.permissions (name, guard_name, created_at, updated_at)
VALUES
    ('approve-cash-funds', 'web', NOW(), NOW()),
    ('close-cash-funds', 'web', NOW(), NOW())
ON CONFLICT (name, guard_name) DO NOTHING;
```

---

## 👥 ASIGNACIÓN DE PERMISOS

### A Usuarios Individuales

```php
use App\Models\User;

$user = User::find(1);

// Dar ambos permisos
$user->givePermissionTo('approve-cash-funds');
$user->givePermissionTo('close-cash-funds');

// O en una sola línea
$user->givePermissionTo(['approve-cash-funds', 'close-cash-funds']);
```

### A Roles

```php
use Spatie\Permission\Models\Role;

// Crear rol de Supervisor
$supervisor = Role::create(['name' => 'supervisor']);
$supervisor->givePermissionTo('approve-cash-funds');

// Crear rol de Gerente
$gerente = Role::create(['name' => 'gerente']);
$gerente->givePermissionTo(['approve-cash-funds', 'close-cash-funds']);

// Asignar rol a usuario
$user = User::find(1);
$user->assignRole('gerente');
```

### Seeder Completo de Roles y Permisos

`database/seeders/RolesAndPermissionsSeeder.php`

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Models\User;

class RolesAndPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        // Reset cached roles and permissions
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        // Crear permisos de Caja Chica
        Permission::create(['name' => 'approve-cash-funds']);
        Permission::create(['name' => 'close-cash-funds']);

        // Crear roles con permisos
        $cajero = Role::create(['name' => 'cajero']);
        // Cajeros no tienen permisos especiales (solo usan el módulo básico)

        $supervisor = Role::create(['name' => 'supervisor']);
        $supervisor->givePermissionTo('approve-cash-funds');

        $gerente = Role::create(['name' => 'gerente']);
        $gerente->givePermissionTo(['approve-cash-funds', 'close-cash-funds']);

        $admin = Role::create(['name' => 'admin']);
        $admin->givePermissionTo(Permission::all()); // Todos los permisos

        $this->command->info('✅ Roles y permisos creados correctamente');
    }
}
```

---

## 🔍 VERIFICACIÓN DE PERMISOS

### En Tinker

```php
use App\Models\User;

$user = User::find(1);

// Verificar permisos individuales
$user->can('approve-cash-funds');  // true/false
$user->can('close-cash-funds');    // true/false

// Ver todos los permisos del usuario
$user->getAllPermissions();

// Ver roles del usuario
$user->roles;
```

### En Blade

```blade
@can('approve-cash-funds')
    <button>Aprobar Fondo</button>
@endcan

@can('close-cash-funds')
    <button>Cerrar Definitivamente</button>
@endcan
```

### En Controlador/Componente

```php
use Illuminate\Support\Facades\Auth;

if (Auth::user()->can('approve-cash-funds')) {
    // Usuario puede aprobar
}

// O usar gate
abort_unless(Auth::user()->can('close-cash-funds'), 403);

// O middleware en rutas (ya implementado)
Route::get('/approvals', Approvals::class)
    ->middleware('can:approve-cash-funds');
```

---

## 🚨 FLUJO DE PERMISOS

### Escenario 1: Usuario sin permisos
```
Usuario → /cashfund/approvals
Sistema → 403 Forbidden
```

### Escenario 2: Usuario con `approve-cash-funds` solamente
```
Usuario → /cashfund/approvals ✅
Usuario → Ver fondos EN_REVISION ✅
Usuario → Aprobar movimientos ✅
Usuario → Rechazar fondo ✅
Usuario → Cerrar fondo definitivamente ❌ (necesita close-cash-funds)
```

### Escenario 3: Usuario con ambos permisos
```
Usuario → /cashfund/approvals ✅
Usuario → Todas las acciones disponibles ✅
```

---

## 📊 MATRIZ DE PERMISOS

| Acción | Sin permisos | approve-cash-funds | close-cash-funds | Ambos |
|--------|--------------|-------------------|------------------|-------|
| Acceder a /cashfund/approvals | ❌ | ✅ | ❌ | ✅ |
| Ver lista de fondos EN_REVISION | ❌ | ✅ | ❌ | ✅ |
| Ver detalle de fondo | ❌ | ✅ | ❌ | ✅ |
| Aprobar movimiento sin comprobante | ❌ | ✅ | ❌ | ✅ |
| Rechazar fondo | ❌ | ✅ | ❌ | ✅ |
| Cerrar fondo definitivamente | ❌ | ❌ | ⚠️ | ✅ |

⚠️ = Requiere también `approve-cash-funds` para acceder al módulo

---

## 🛡️ SEGURIDAD

### Validaciones Implementadas

**En Rutas:**
```php
Route::get('/approvals', Approvals::class)
    ->middleware('can:approve-cash-funds')
    ->name('cashfund.approvals');
```

**En Componente:**
```php
public function mount()
{
    if (!Auth::user()->can('approve-cash-funds')) {
        abort(403, 'No tienes permisos para aprobar fondos');
    }
}
```

**En Métodos:**
```php
public function approveFund()
{
    if (!Auth::user()->can('close-cash-funds')) {
        $this->dispatch('toast',
            type: 'error',
            body: 'No tienes permisos para cerrar fondos definitivamente'
        );
        return;
    }
    // ...
}
```

**En Vista:**
```blade
@if($canApprove)
    <button wire:click="openRejectModal">Rechazar</button>
@endif

@if($canClose)
    <button wire:click="openApproveModal">Cerrar</button>
@endif
```

---

## 📝 RECOMENDACIONES

### Para Producción:

1. **Separar permisos por rol:**
   - Cajeros: Sin permisos especiales
   - Supervisores: `approve-cash-funds`
   - Gerentes: `approve-cash-funds` + `close-cash-funds`
   - Admins: Todos los permisos

2. **Auditar asignación de permisos:**
   ```php
   // Listar todos los usuarios con permisos de cerrar fondos
   $users = User::permission('close-cash-funds')->get();
   ```

3. **Revisar periódicamente:**
   - Quién tiene permisos
   - Cuándo se usan
   - Crear logs de acciones sensibles

4. **Agregar más permisos granulares (opcional):**
   ```php
   'approve-movements-without-receipt'  // Aprobar solo movimientos
   'reject-funds'                       // Solo rechazar
   'close-funds-with-differences'       // Cerrar con diferencias
   ```

---

## 🔗 RECURSOS

**Documentación Spatie:**
- https://spatie.be/docs/laravel-permission/v6/introduction

**Comandos útiles:**
```bash
# Limpiar cache de permisos
php artisan permission:cache-reset

# Ver todos los permisos
php artisan tinker
>>> Spatie\Permission\Models\Permission::all();

# Ver todos los roles
>>> Spatie\Permission\Models\Role::with('permissions')->get();
```

---

## ✅ CHECKLIST DE INSTALACIÓN

- [ ] Crear permisos `approve-cash-funds` y `close-cash-funds`
- [ ] Crear roles (opcional): cajero, supervisor, gerente
- [ ] Asignar permisos a roles
- [ ] Asignar roles a usuarios
- [ ] Verificar acceso a `/cashfund/approvals`
- [ ] Probar flujo completo de aprobación
- [ ] Probar flujo completo de cierre
- [ ] Verificar mensajes de error cuando no hay permisos

---

**Documento generado:** 2025-10-23
**Sistema:** Spatie Laravel Permission
**Ready for:** Asignación de permisos y pruebas
