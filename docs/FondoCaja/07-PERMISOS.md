# 07 - SISTEMA DE PERMISOS

## 🔐 Arquitectura de Permisos

El sistema utiliza **Spatie Laravel Permission** para control de acceso granular.

**Paquete:** `spatie/laravel-permission`
**Documentación:** https://spatie.be/docs/laravel-permission

---

## 🎫 Permisos Definidos

### 1. approve-cash-funds

**Descripción:** Permite revisar fondos en estado EN_REVISION

**Capacidades:**
- ✅ Acceder a `/cashfund/approvals`
- ✅ Ver fondos pendientes de aprobación
- ✅ Ver detalles completos de fondos
- ✅ Rechazar fondos (reabrir)
- ❌ No puede cerrar definitivamente (necesita otro permiso)

**Asignar a:**
- Supervisores
- Gerentes
- Contadores

---

### 2. close-cash-funds

**Descripción:** Permite cerrar fondos definitivamente

**Capacidades:**
- ✅ Aprobar fondos después de revisión
- ✅ Cambiar estado a CERRADO
- ✅ Marcar movimientos como APROBADO
- ✅ Registrar `closed_at`

**Asignar a:**
- Gerentes
- Directores
- Administradores

**⚠️ Importante:** Este permiso implica responsabilidad financiera. Otorgar solo a personal autorizado.

---

## 📋 Instalación de Permisos

### Método 1: Tinker (Recomendado para Desarrollo)

```bash
php artisan tinker
```

```php
// Crear permisos
\Spatie\Permission\Models\Permission::create(['name' => 'approve-cash-funds']);
\Spatie\Permission\Models\Permission::create(['name' => 'close-cash-funds']);

// Asignar a usuario específico
$user = \App\Models\User::find(1);
$user->givePermissionTo('approve-cash-funds');
$user->givePermissionTo('close-cash-funds');

// Verificar
$user->hasPermissionTo('approve-cash-funds'); // true
```

---

### Método 2: Seeder (Recomendado para Producción)

**Crear seeder:**
```bash
php artisan make:seeder CashFundPermissionsSeeder
```

**Archivo:** `database/seeders/CashFundPermissionsSeeder.php`

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class CashFundPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        // Crear permisos
        Permission::create(['name' => 'approve-cash-funds']);
        Permission::create(['name' => 'close-cash-funds']);

        // Crear roles (opcional)
        $supervisor = Role::create(['name' => 'supervisor']);
        $gerente = Role::create(['name' => 'gerente']);

        // Asignar permisos a roles
        $supervisor->givePermissionTo('approve-cash-funds');
        $gerente->givePermissionTo(['approve-cash-funds', 'close-cash-funds']);

        // Asignar roles a usuarios
        $usuarioSupervisor = \App\Models\User::where('email', 'supervisor@terrena.com')->first();
        if ($usuarioSupervisor) {
            $usuarioSupervisor->assignRole('supervisor');
        }

        $usuarioGerente = \App\Models\User::where('email', 'gerente@terrena.com')->first();
        if ($usuarioGerente) {
            $usuarioGerente->assignRole('gerente');
        }
    }
}
```

**Ejecutar:**
```bash
php artisan db:seed --class=CashFundPermissionsSeeder
```

---

### Método 3: SQL Directo

```sql
-- Insertar permisos
INSERT INTO permissions (name, guard_name, created_at, updated_at)
VALUES
    ('approve-cash-funds', 'web', NOW(), NOW()),
    ('close-cash-funds', 'web', NOW(), NOW());

-- Asignar permiso a usuario (ejemplo: usuario ID 1)
INSERT INTO model_has_permissions (permission_id, model_type, model_id)
SELECT id, 'App\\Models\\User', 1
FROM permissions
WHERE name IN ('approve-cash-funds', 'close-cash-funds');
```

---

## 🔍 Uso de Permisos

### En Componentes Livewire

```php
use Illuminate\Support\Facades\Auth;

class Approvals extends Component
{
    public function mount()
    {
        // Validar en mount
        if (!Auth::user()->can('approve-cash-funds')) {
            abort(403, 'No tienes permisos para aprobar fondos');
        }
    }

    public function approveFund()
    {
        // Validar en método específico
        if (!Auth::user()->can('close-cash-funds')) {
            $this->dispatch('toast',
                type: 'error',
                body: 'No tienes permisos para cerrar fondos'
            );
            return;
        }

        // Proceder con aprobación...
    }
}
```

---

### En Rutas (Middleware)

```php
// routes/web.php

use App\Livewire\CashFund\Approvals;

Route::middleware(['auth'])->group(function () {
    // Ruta protegida por permiso
    Route::get('/cashfund/approvals', Approvals::class)
        ->middleware('can:approve-cash-funds')
        ->name('cashfund.approvals');
});
```

---

### En Vistas Blade

```blade
{{-- Mostrar botón solo si tiene permiso --}}
@can('approve-cash-funds')
    <a href="{{ route('cashfund.approvals') }}" class="btn btn-warning">
        <i class="fa-solid fa-check-double"></i>
        Aprobaciones
    </a>
@endcan

{{-- Mostrar contenido diferente según permiso --}}
@can('close-cash-funds')
    <button wire:click="approveFund">Aprobar y Cerrar</button>
@else
    <p class="text-muted">No tienes permisos para cerrar fondos</p>
@endcan

{{-- Verificar múltiples permisos --}}
@canany(['approve-cash-funds', 'close-cash-funds'])
    <div class="admin-panel">
        {{-- Contenido para usuarios con alguno de los permisos --}}
    </div>
@endcanany
```

---

## 👥 Gestión de Usuarios

### Asignar Permisos a Usuario

```php
$user = User::find(1);

// Un permiso
$user->givePermissionTo('approve-cash-funds');

// Múltiples permisos
$user->givePermissionTo(['approve-cash-funds', 'close-cash-funds']);

// Sincronizar (reemplazar todos los permisos)
$user->syncPermissions(['approve-cash-funds']);
```

---

### Revocar Permisos

```php
$user = User::find(1);

// Un permiso
$user->revokePermissionTo('approve-cash-funds');

// Múltiples permisos
$user->revokePermissionTo(['approve-cash-funds', 'close-cash-funds']);

// Todos los permisos
$user->permissions()->detach();
```

---

### Verificar Permisos

```php
$user = User::find(1);

// Verificar un permiso
$user->hasPermissionTo('approve-cash-funds'); // true/false

// Verificar múltiples (tiene TODOS)
$user->hasAllPermissions(['approve-cash-funds', 'close-cash-funds']); // true/false

// Verificar múltiples (tiene ALGUNO)
$user->hasAnyPermission(['approve-cash-funds', 'close-cash-funds']); // true/false
```

---

## 🏢 Trabajar con Roles (Opcional)

### Crear Roles

```php
use Spatie\Permission\Models\Role;

$supervisor = Role::create(['name' => 'supervisor']);
$gerente = Role::create(['name' => 'gerente']);
$cajero = Role::create(['name' => 'cajero']);
```

---

### Asignar Permisos a Roles

```php
$supervisor = Role::findByName('supervisor');
$supervisor->givePermissionTo('approve-cash-funds');

$gerente = Role::findByName('gerente');
$gerente->givePermissionTo(['approve-cash-funds', 'close-cash-funds']);
```

---

### Asignar Roles a Usuarios

```php
$user = User::find(1);

// Un rol
$user->assignRole('gerente');

// Múltiples roles
$user->assignRole(['gerente', 'supervisor']);

// Verificar
$user->hasRole('gerente'); // true/false
```

---

### Verificar en Blade

```blade
@role('gerente')
    <p>Eres gerente</p>
@endrole

@hasrole('gerente')
    <p>Tienes el rol de gerente</p>
@endhasrole

@hasanyrole('gerente|supervisor')
    <p>Eres gerente o supervisor</p>
@endhasanyrole
```

---

## 🔒 Matriz de Permisos Recomendada

| Rol | approve-cash-funds | close-cash-funds | Descripción |
|-----|-------------------|------------------|-------------|
| **Cajero** | ❌ | ❌ | Solo puede abrir fondos y registrar movimientos |
| **Supervisor** | ✅ | ❌ | Puede revisar y rechazar, pero no cerrar |
| **Gerente** | ✅ | ✅ | Control completo sobre aprobaciones |
| **Admin** | ✅ | ✅ | Acceso total al sistema |

---

## 🛡️ Mejores Prácticas

### 1. Principio de Menor Privilegio
Otorgar solo los permisos necesarios para cada rol.

```php
// ❌ MAL: Dar todos los permisos
$user->givePermissionTo(Permission::all());

// ✅ BIEN: Dar solo lo necesario
$user->givePermissionTo(['approve-cash-funds']);
```

---

### 2. Separación de Responsabilidades
No permitir que la misma persona que registra movimientos pueda aprobarlos.

```php
// Validar en el componente
public function approveFund()
{
    if ($this->selectedFondo->responsable_user_id === Auth::id()) {
        $this->dispatch('toast',
            type: 'error',
            body: 'No puedes aprobar tu propio fondo'
        );
        return;
    }
}
```

---

### 3. Auditar Cambios de Permisos

Registrar quién otorga/revoca permisos:

```php
// En un Observer o Controller
Log::info('Permiso otorgado', [
    'usuario' => $user->id,
    'permiso' => 'approve-cash-funds',
    'otorgado_por' => Auth::id(),
    'timestamp' => now()
]);
```

---

### 4. Cache de Permisos

Spatie cachea los permisos automáticamente. Si modificas permisos directamente en BD:

```bash
php artisan permission:cache-reset
```

---

## 📊 Consultas Útiles

### Listar usuarios con permiso específico

```php
$users = User::permission('approve-cash-funds')->get();
```

---

### Listar todos los permisos de un usuario

```php
$user = User::find(1);
$permisos = $user->getAllPermissions();

foreach ($permisos as $permiso) {
    echo $permiso->name . "\n";
}
```

---

### Usuarios sin permisos de caja chica

```sql
SELECT u.*
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM model_has_permissions mhp
    JOIN permissions p ON p.id = mhp.permission_id
    WHERE mhp.model_id = u.id
    AND mhp.model_type = 'App\\Models\\User'
    AND p.name IN ('approve-cash-funds', 'close-cash-funds')
);
```

---

## 🔧 Troubleshooting

### Error: "This action is unauthorized"

**Causa:** Usuario no tiene el permiso requerido

**Solución:**
```php
$user = User::find(Auth::id());
$user->givePermissionTo('approve-cash-funds');

// Limpiar cache
php artisan permission:cache-reset
```

---

### Error: "Permission does not exist"

**Causa:** El permiso no está creado en la tabla `permissions`

**Solución:**
```php
Permission::create(['name' => 'approve-cash-funds']);
```

---

### Middleware no funciona

**Causa:** Middleware de Spatie no registrado

**Verificar:** `app/Http/Kernel.php`
```php
protected $middlewareAliases = [
    'role' => \Spatie\Permission\Middleware\RoleMiddleware::class,
    'permission' => \Spatie\Permission\Middleware\PermissionMiddleware::class,
    'role_or_permission' => \Spatie\Permission\Middleware\RoleOrPermissionMiddleware::class,
];
```
