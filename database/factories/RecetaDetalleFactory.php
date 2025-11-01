<?php

namespace Database\Factories\Rec;

use App\Models\Rec\RecetaDetalle;
use App\Models\Rec\RecetaVersion;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Rec\RecetaDetalle>
 */
class RecetaDetalleFactory extends Factory
{
    protected $model = RecetaDetalle::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'receta_version_id' => RecetaVersion::factory(),
            'item_id' => 'ITEM-' . strtoupper($this->faker->unique()->lexify('????')),
            'cantidad' => $this->faker->randomFloat(2, 10, 500),
            'unidad_medida' => $this->faker->randomElement(['GR', 'ML', 'UND', 'KG', 'LT']),
            'merma_porcentaje' => $this->faker->randomFloat(2, 0, 10),
            'instrucciones_especificas' => $this->faker->optional()->sentence(),
            'orden' => 1,
            'created_at' => now(),
        ];
    }
}
