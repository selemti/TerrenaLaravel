<?php

namespace Database\Factories;

use App\Models\Item;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class ItemFactory extends Factory
{
    protected $model = Item::class;

    public function definition(): array
    {
        $id = 'ITEM-' . strtoupper(Str::random(5));

        return [
            'id' => $id,
            'codigo' => strtoupper(Str::random(6)),
            'nombre' => $this->faker->words(2, true),
            'categoria_id' => null,
            'perishable' => false,
            'activo' => true,
            'costo_promedio' => $this->faker->randomFloat(2, 10, 200),
            'factor_conversion' => 1,
            'factor_compra' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
