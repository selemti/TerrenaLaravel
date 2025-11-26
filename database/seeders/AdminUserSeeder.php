<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        // La tabla selemti.users solo tiene: id, name, email, password, email_verified_at, remember_token, created_at, updated_at
        $user = User::query()->updateOrCreate(
            ['email' => 'soporte@selemti.com'],
            [
                'name' => 'Usuario Soporte',
                'password' => Hash::make('soporte'), // Password original del usuario
            ]
        );

        // Sincronizar roles si la tabla existe
        try {
            $user->syncRoles(['Super Admin']);
        } catch (\Exception $e) {
            $this->command->warn('No se pudieron asignar roles: '.$e->getMessage());
        }

        $this->command->info('Usuario creado: email=soporte@selemti.com / password=soporte');
    }
}
