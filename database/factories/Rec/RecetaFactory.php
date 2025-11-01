<?php

namespace Database\Factories\Rec;

use App\Models\Inv\Item;
use App\Models\Rec\Receta;
use Illuminate\Database\Eloquent\Factories\Factory;

class RecetaFactory extends Factory
{
    protected $model = Receta::class;

    public function definition(): array
    {
        return [
            'id' => 'REC-' . strtoupper($this->faker->unique()->bothify('??###')),
            'nombre_plato' => $this->faker->words(3, true),
            'codigo_plato_pos' => $this->faker->unique()->numerify('PLT-####'),
            'categoria_plato' => $this->faker->randomElement(['ENTRADA', 'PLATO_FUERTE', 'POSTRE', 'BEBIDA']),
            'porciones_standard' => $this->faker->numberBetween(1, 10),
            'instrucciones_preparacion' => $this->faker->paragraph(),
            'tiempo_preparacion_min' => $this->faker->numberBetween(5, 120),
            'costo_standard_porcion' => $this->faker->randomFloat(4, 10, 200),
            'precio_venta_sugerido' => $this->faker->randomFloat(2, 50, 500),
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'activo' => false,
        ]);
    }
}
