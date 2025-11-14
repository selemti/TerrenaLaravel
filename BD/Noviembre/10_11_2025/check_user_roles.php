<?php

// Script temporal para verificar roles de usuario en producción

require __DIR__.'/../../../vendor/autoload.php';

$app = require_once __DIR__.'/../../../bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "=== VERIFICACIÓN DE ROLES Y USUARIOS ===\n\n";

// Verificar todos los usuarios
echo "Usuarios en selemti.users:\n";
$users = DB::connection('pgsql')->table('selemti.users')->get();
foreach ($users as $user) {
    echo "  ID: {$user->id} | Email: {$user->email} | Name: {$user->name}\n";
}

echo "\n";

// Verificar model_has_roles
echo "Asignaciones en model_has_roles:\n";
$assignments = DB::connection('pgsql')
    ->table('selemti.model_has_roles')
    ->get();

foreach ($assignments as $assignment) {
    echo "  Model Type: {$assignment->model_type}\n";
    echo "  Model ID: {$assignment->model_id}\n";
    echo "  Role ID: {$assignment->role_id}\n";

    // Buscar el nombre del rol
    $role = DB::connection('pgsql')
        ->table('selemti.roles')
        ->where('id', $assignment->role_id)
        ->first();

    if ($role) {
        echo "  Role Name: {$role->name}\n";
    }
    echo "\n";
}

// Verificar roles disponibles
echo "Roles disponibles:\n";
$roles = DB::connection('pgsql')->table('selemti.roles')->get();
foreach ($roles as $role) {
    echo "  ID: {$role->id} | Name: {$role->name}\n";
}

echo "\n";

// Intentar usar el modelo User de Eloquent
echo "Verificando con Eloquent Model:\n";
$eloquentUser = \App\Models\User::where('email', 'soporte@terrena.com')->first();
if ($eloquentUser) {
    echo "  User found: {$eloquentUser->name} ({$eloquentUser->email})\n";
    echo "  User ID: {$eloquentUser->id}\n";

    // Verificar roles usando Spatie
    $userRoles = $eloquentUser->roles;
    echo '  Roles asignados: '.$userRoles->count()."\n";
    foreach ($userRoles as $role) {
        echo "    - {$role->name}\n";
    }
} else {
    echo "  Usuario soporte@terrena.com NO ENCONTRADO\n";
}

echo "\n=== FIN DE VERIFICACIÓN ===\n";
