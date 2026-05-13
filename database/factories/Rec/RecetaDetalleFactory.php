<?php

namespace Database\Factories\Rec;

use App\Models\Inv\Item;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaDetalle;
use Illuminate\Database\Eloquent\Factories\Factory;

class RecetaDetalleFactory extends Factory
{
    protected $model = RecetaDetalle::class;

    public function definition(): array
    {
        return [
            'receta_id' => Receta::factory(),
            'item_id' => Item::factory(),
            'cantidad' => $this->faker->randomFloat(4, 0.1, 100),
            'unidad_id' => null,
            'orden' => $this->faker->numberBetween(1, 20),
        ];
    }
}
