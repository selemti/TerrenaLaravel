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
            'item_code' => strtoupper(Str::random(6)),
            'nombre' => $this->faker->words(2, true),
            'descripcion' => null,
            'categoria_id' => 'CAT-TEST',
            'unidad_medida' => 'PZ',
            'perishable' => false,
            'costo_promedio' => $this->faker->randomFloat(2, 5, 200),
            'activo' => true,
            'factor_conversion' => 1,
            'factor_compra' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
