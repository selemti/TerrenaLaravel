<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $password = Hash::make('Terrena123#');

        $user = User::query()->updateOrCreate(
            ['email' => 'soporte@selemti.com'],
            [
                'username' => 'soporte',
                'password_hash' => $password,
                'nombre_completo' => 'Soporte SelemTI',
                'sucursal_id' => 'CENTRO',
                'activo' => true,
                'intentos_login' => 0,
            ]
        );

        $user->syncRoles(['Super Admin']);
    }
}

