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
            'clave' => strtoupper($this->faker->unique()->bothify('ITEM-###??')),
            'nombre' => $this->faker->words(3, true),
            'descripcion' => $this->faker->sentence(),
            'categoria_id' => 1,
            'unidad_medida' => $this->faker->randomElement(['PZ', 'KG', 'LT', 'MT']),
            'tipo' => $this->faker->randomElement(['INSUMO', 'PRODUCTO', 'SERVICIO']),
            'activo' => true,
            'costo_promedio' => $this->faker->randomFloat(2, 10, 1000),
            'precio_venta' => $this->faker->randomFloat(2, 50, 2000),
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
