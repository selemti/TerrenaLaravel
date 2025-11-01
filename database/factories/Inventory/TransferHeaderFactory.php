<?php

namespace Database\Factories\Inventory;

use App\Models\Inventory\TransferHeader;
use Illuminate\Database\Eloquent\Factories\Factory;

class TransferHeaderFactory extends Factory
{
    protected $model = TransferHeader::class;

    public function definition(): array
    {
        return [
            'origen_almacen_id' => 1,
            'destino_almacen_id' => 2,
            'estado' => TransferHeader::STATUS_SOLICITADA,
            'creada_por' => 1,
            'fecha_solicitada' => now(),
            'observaciones' => $this->faker->optional()->sentence(),
        ];
    }

    public function aprobada(): static
    {
        return $this->state(function () {
            return [
                'estado' => TransferHeader::STATUS_APROBADA,
                'aprobada_por' => 1,
                'fecha_aprobada' => now(),
            ];
        });
    }

    public function enTransito(): static
    {
        return $this->state(function () {
            return [
                'estado' => TransferHeader::STATUS_EN_TRANSITO,
                'aprobada_por' => 1,
                'despachada_por' => 1,
                'fecha_aprobada' => now()->subHour(),
                'fecha_despachada' => now(),
                'guia' => 'GUIA-' . $this->faker->numerify('####'),
            ];
        });
    }

    public function recibida(): static
    {
        return $this->state(function () {
            return [
                'estado' => TransferHeader::STATUS_RECIBIDA,
                'aprobada_por' => 1,
                'despachada_por' => 1,
                'recibida_por' => 1,
                'fecha_aprobada' => now()->subHours(2),
                'fecha_despachada' => now()->subHour(),
                'fecha_recibida' => now(),
            ];
        });
    }
}
