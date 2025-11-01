<?php

namespace Database\Factories\Inventory;

use App\Models\Inv\Item;
use App\Models\Inventory\TransferLine;
use App\Models\Inventory\TransferHeader;
use Illuminate\Database\Eloquent\Factories\Factory;

class TransferLineFactory extends Factory
{
    protected $model = TransferLine::class;

    public function definition(): array
    {
        return [
            'transfer_id' => TransferHeader::factory(),
            'item_id' => Item::factory(),
            'cantidad_solicitada' => $this->faker->randomFloat(2, 1, 100),
            'cantidad_despachada' => null,
            'cantidad_recibida' => null,
            'unidad_medida' => 'PZ',
            'observaciones' => $this->faker->optional()->sentence(),
            'created_at' => now(),
        ];
    }

    public function despachada(): static
    {
        return $this->state(function (array $attributes) {
            return [
                'cantidad_despachada' => $attributes['cantidad_solicitada'],
            ];
        });
    }

    public function recibida(): static
    {
        return $this->state(function (array $attributes) {
            $solicitada = $attributes['cantidad_solicitada'];
            return [
                'cantidad_despachada' => $solicitada,
                'cantidad_recibida' => $solicitada,
            ];
        });
    }

    public function conVarianza(): static
    {
        return $this->state(function (array $attributes) {
            $solicitada = $attributes['cantidad_solicitada'];
            $despachada = $solicitada;
            $recibida = $despachada * 0.9;
            
            return [
                'cantidad_despachada' => $despachada,
                'cantidad_recibida' => $recibida,
                'observaciones_recepcion' => 'Varianza detectada',
            ];
        });
    }
}
