<?php

namespace Database\Factories\Catalogs;

use App\Models\Catalogs\Unidad;
use Illuminate\Database\Eloquent\Factories\Factory;

class UnidadFactory extends Factory
{
    protected $model = Unidad::class;

    public function definition(): array
    {
        $tipos = ['PESO', 'VOLUMEN', 'LONGITUD', 'UNIDAD'];
        $tipo = $this->faker->randomElement($tipos);

        return [
            'codigo' => strtoupper($this->faker->unique()->lexify('??')),
            'nombre' => $this->faker->word(),
            'tipo' => $tipo,
            'categoria' => $this->faker->randomElement(['COMUN', 'ESPECIAL']),
            'es_base' => $this->faker->boolean(20),
            'factor_conversion_base' => $this->faker->randomFloat(4, 0.001, 1000),
            'decimales' => $this->faker->numberBetween(0, 4),
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
