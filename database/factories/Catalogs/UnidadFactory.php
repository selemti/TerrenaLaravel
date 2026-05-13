<?php

namespace Database\Factories\Catalogs;

use App\Models\Catalogs\Unidad;
use Illuminate\Database\Eloquent\Factories\Factory;

class UnidadFactory extends Factory
{
    protected $model = Unidad::class;

    public function definition(): array
    {
        return [
            'clave' => strtoupper($this->faker->unique()->lexify('??')),
            'nombre' => $this->faker->word(),
            'categoria' => $this->faker->randomElement(['BASE', 'COCINA', 'COMPRA', 'PORCION']),
            'activo' => true,
        ];
    }
}
