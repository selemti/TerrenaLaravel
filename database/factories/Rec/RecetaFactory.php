<?php

namespace Database\Factories\Rec;

use App\Models\Rec\Receta;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class RecetaFactory extends Factory
{
    protected $model = Receta::class;

    public function definition(): array
    {
        $id = 'REC-' . strtoupper(Str::random(6));

        return [
            'id' => $id,
            'nombre_plato' => $this->faker->unique()->words(3, true),
            'codigo_plato_pos' => strtoupper(Str::random(5)),
            'categoria_plato' => $this->faker->randomElement(['BEBIDAS', 'COMIDAS', 'POSTRES']),
            'porciones_standard' => $this->faker->numberBetween(1, 6),
            'instrucciones_preparacion' => null,
            'tiempo_preparacion_min' => $this->faker->numberBetween(5, 45),
            'costo_standard_porcion' => 0,
            'precio_venta_sugerido' => $this->faker->numberBetween(40, 160),
            'activo' => true,
        ];
    }
}
