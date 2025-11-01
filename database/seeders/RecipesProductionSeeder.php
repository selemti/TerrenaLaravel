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
            ->table('selemti.receta_cab')
            ->where('id', 'REC-DEMO-001')
            ->exists();

        if ($exists) {
            return;
        }

        DB::connection('pgsql')->table('selemti.receta_cab')->insert([
            'id' => 'REC-DEMO-001',
            'nombre_plato' => 'Receta de Ejemplo',
            'codigo_plato_pos' => 'DEMO-001',
            'categoria_plato' => 'DEMO',
            'porciones_standard' => 4,
            'tiempo_preparacion_min' => 30,
            'costo_standard_porcion' => 0,
            'precio_venta_sugerido' => 0,
            'activo' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::connection('pgsql')->table('selemti.receta_version')->insert([
            'receta_id' => 'REC-DEMO-001',
            'version' => 1,
            'descripcion_cambios' => 'Versión inicial de demostración',
            'fecha_efectiva' => $now->toDateString(),
            'version_publicada' => false,
            'usuario_publicador' => null,
            'fecha_publicacion' => null,
            'created_at' => $now,
        ]);

        $this->command?->info('  ➜ Receta demo REC-DEMO-001 registrada.');
    }
}
