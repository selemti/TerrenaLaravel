#!/usr/bin/env php
<?php
/**
 * Script para limpiar el caché de permisos de Spatie
 * Este script debe ejecutarse en el servidor después de modificar roles/permisos
 */

require __DIR__ . '/../../../vendor/autoload.php';

$app = require_once __DIR__ . '/../../../bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "=== LIMPIANDO CACHÉ DE PERMISOS ===\n\n";

// Limpiar caché de Spatie Permission
echo "1. Limpiando caché de Spatie Permission...\n";
app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();
echo "   ✓ Caché de permisos limpiado\n\n";

// Limpiar caché general de Laravel
echo "2. Limpiando caché general de Laravel...\n";
\Illuminate\Support\Facades\Artisan::call('cache:clear');
echo "   ✓ Caché general limpiado\n\n";

// Limpiar caché de configuración
echo "3. Limpiando caché de configuración...\n";
\Illuminate\Support\Facades\Artisan::call('config:clear');
echo "   ✓ Caché de configuración limpiado\n\n";

echo "=== VERIFICANDO PERMISOS DEL USUARIO soporte@terrena.com ===\n\n";

$user = \App\Models\User::where('email', 'soporte@terrena.com')->first();

if (!$user) {
    echo "ERROR: Usuario no encontrado\n";
    exit(1);
}

echo "Usuario: {$user->name} ({$user->email})\n";
echo "ID: {$user->id}\n\n";

// Verificar roles
$roles = $user->roles;
echo "Roles asignados: " . $roles->count() . "\n";
foreach ($roles as $role) {
    echo "  - {$role->name}\n";
}
echo "\n";

// Verificar permisos
if ($user->hasRole('Super Admin')) {
    echo "✓ El usuario tiene el rol 'Super Admin'\n";
    echo "✓ Este rol debe tener acceso completo al sistema\n\n";

    // Verificar cuántos permisos tiene el rol
    $superAdminRole = \Spatie\Permission\Models\Role::where('name', 'Super Admin')->first();
    if ($superAdminRole) {
        $perms = $superAdminRole->permissions()->count();
        echo "  El rol 'Super Admin' tiene {$perms} permisos asignados\n";
    }
} else {
    echo "✗ ADVERTENCIA: El usuario NO tiene el rol 'Super Admin'\n";
}

echo "\n=== PRÓXIMOS PASOS ===\n\n";
echo "1. El usuario debe CERRAR SESIÓN en la aplicación\n";
echo "2. Volver a INICIAR SESIÓN\n";
echo "3. Verificar que ahora puede ver todos los menús\n\n";

echo "=== FIN ===\n";
