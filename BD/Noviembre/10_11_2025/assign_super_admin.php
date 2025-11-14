<?php

// Script para asignar rol Super Admin al usuario soporte

require __DIR__.'/../../../vendor/autoload.php';

$app = require_once __DIR__.'/../../../bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User;
use Spatie\Permission\Models\Role;

echo "Asignando rol Super Admin al usuario soporte...\n\n";

// Buscar usuario soporte
$user = User::where('email', 'soporte@terrena.com')->first();

if (! $user) {
    echo "ERROR: Usuario soporte@terrena.com NO ENCONTRADO\n";
    echo "Buscando todos los usuarios...\n";
    $allUsers = User::all();
    foreach ($allUsers as $u) {
        echo "  - ID: {$u->id} | Email: {$u->email} | Name: {$u->name}\n";
    }
    exit(1);
}

echo "Usuario encontrado:\n";
echo "  ID: {$user->id}\n";
echo "  Email: {$user->email}\n";
echo "  Name: {$user->name}\n\n";

// Buscar rol Super Admin
$role = Role::where('name', 'Super Admin')->first();

if (! $role) {
    echo "ERROR: Rol 'Super Admin' NO ENCONTRADO\n";
    echo "Roles disponibles:\n";
    $allRoles = Role::all();
    foreach ($allRoles as $r) {
        echo "  - ID: {$r->id} | Name: {$r->name}\n";
    }
    exit(1);
}

echo "Rol encontrado:\n";
echo "  ID: {$role->id}\n";
echo "  Name: {$role->name}\n\n";

// Verificar si ya tiene el rol
if ($user->hasRole('Super Admin')) {
    echo "El usuario YA TIENE el rol 'Super Admin'\n";
} else {
    echo "Asignando rol 'Super Admin'...\n";
    $user->assignRole('Super Admin');
    echo "✓ Rol asignado correctamente\n";
}

// Verificar permisos
echo "\nVerificando permisos del usuario...\n";
$permissions = $user->getAllPermissions();
echo 'Total permisos: '.$permissions->count()."\n";

if ($user->hasRole('Super Admin')) {
    echo "\n✓ Usuario tiene rol 'Super Admin' correctamente asignado\n";
    echo "✓ El usuario debería tener acceso completo al sistema\n";
} else {
    echo "\n✗ ERROR: Usuario AÚN NO TIENE el rol 'Super Admin'\n";
}

echo "\n=== FIN ===\n";
