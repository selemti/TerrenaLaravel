<?php

namespace Database\Seeders;

use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class RecipesProductionSeeder extends Seeder
{
    public function run(): void
    {
        DB::connection('pgsql')->beginTransaction();

        try {
            $this->seedDemoRecipe();
            DB::connection('pgsql')->commit();
            $this->command?->info('✅ Recetas demo creadas.');
        } catch (\Throwable $exception) {
            DB::connection('pgsql')->rollBack();
            $this->command?->error('❌ Error creando recetas demo: ' . $exception->getMessage());
            throw $exception;
        }
    }

    private function seedDemoRecipe(): void
    {
        $now = Carbon::now();

        $exists = DB::connection('pgsql')
            ->table('selemti.recipes')
            ->where('id', 'REC-DEMO-001')
            ->exists();

        if ($exists) {
            return;
        }

        DB::connection('pgsql')->table('selemti.recipes')->insert([
            'id' => 'REC-DEMO-001',
            'codigo' => 'DEMO-001',
            'nombre' => 'Receta de Ejemplo',
            'descripcion' => 'Receta base de referencia para capacitación.',
            'porciones' => 4,
            'tiempo_preparacion' => 30,
            'activo' => true,
            'created_by_user_id' => 1,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::connection('pgsql')->table('selemti.recipe_versions')->insert([
            'recipe_id' => 'REC-DEMO-001',
            'version_no' => 1,
            'notes' => 'Versión inicial de demostración',
            'valid_from' => $now,
            'created_at' => $now,
        ]);

        $this->command?->info('  ➜ Receta demo REC-DEMO-001 registrada.');
    }
}
