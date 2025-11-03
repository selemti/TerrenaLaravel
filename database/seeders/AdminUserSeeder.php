<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::query()->updateOrCreate(
            ['username' => 'soporte'],
            [
                'email' => 'soporte@terrena.com',
                'nombre_completo' => 'Usuario Soporte',
                'password_hash' => Hash::make('password'), // Cambiar en producción
                'sucursal_id' => 'SUR',
                'activo' => true,
            ]
        );

        // Sincronizar roles si la tabla existe
        try {
            $user->syncRoles(['Super Admin']);
        } catch (\Exception $e) {
            $this->command->warn('No se pudieron asignar roles: ' . $e->getMessage());
        }

        $this->command->info('Usuario creado: username=soporte / password=password');
    }
}

