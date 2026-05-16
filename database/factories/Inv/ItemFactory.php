<?php

namespace Database\Factories\Inv;

use App\Models\Inv\Item;
use Illuminate\Database\Eloquent\Factories\Factory;

class ItemFactory extends Factory
{
    protected $model = Item::class;

    public function definition(): array
    {
        return [
            'id' => strtoupper($this->faker->unique()->bothify('ITEM-###??')),
            'nombre' => $this->faker->words(3, true),
            'activo' => true,
            'costo_promedio' => $this->faker->randomFloat(2, 10, 1000),
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
