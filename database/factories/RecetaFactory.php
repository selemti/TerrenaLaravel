<?php

namespace Database\Factories\Rec;

use App\Models\Rec\Receta;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Rec\Receta>
 */
class RecetaFactory extends Factory
{
    protected $model = Receta::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'id' => 'REC-' . strtoupper($this->faker->unique()->lexify('????')),
            'nombre_plato' => $this->faker->words(3, true),
            'codigo_plato_pos' => $this->faker->optional()->numerify('PLU-####'),
            'categoria_plato' => $this->faker->randomElement(['Entradas', 'Platos Fuertes', 'Postres', 'Bebidas']),
            'porciones_standard' => $this->faker->numberBetween(1, 10),
            'instrucciones_preparacion' => $this->faker->optional()->sentence(),
            'tiempo_preparacion_min' => $this->faker->numberBetween(5, 120),
            'costo_standard_porcion' => $this->faker->randomFloat(2, 10, 200),
            'precio_venta_sugerido' => $this->faker->randomFloat(2, 50, 500),
            'activo' => true,
        ];
    }
}

