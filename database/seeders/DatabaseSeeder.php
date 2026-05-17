<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            PermissionsSeeder::class,
            AdminUserSeeder::class,
            AuditLogDemoSeeder::class,
        ]);

        if ($this->command?->confirm('¿Desea crear catálogos de producción?', true)) {
            $this->call(CatalogosProductionSeeder::class);
        }

        if ($this->command?->confirm('¿Desea crear recetas demo?', true)) {
            $this->call(RecipesProductionSeeder::class);
        }

        if ($this->command?->confirm('¿Ejecutar corrida E2E completa (datos maestros + flujo transaccional)?', false)) {
            $this->call(\Database\Seeders\E2E\MasterDataSeeder::class);
            $this->call(\Database\Seeders\E2E\TransactionalFlowSeeder::class);
        }
    }
}
