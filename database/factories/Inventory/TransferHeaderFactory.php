<?php

namespace Database\Factories\Inventory;

use App\Models\Inventory\TransferHeader;
use App\Models\User;
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
            'creada_por' => User::factory(),
            'fecha_solicitada' => now(),
            'observaciones' => $this->faker->optional()->sentence(),
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }

    public function aprobada(): static
    {
        return $this->state(fn (array $attributes) => [
            'estado' => TransferHeader::STATUS_APROBADA,
            'aprobada_por' => User::factory(),
            'fecha_aprobada' => now(),
        ]);
    }

    public function enTransito(): static
    {
        return $this->state(fn (array $attributes) => [
            'estado' => TransferHeader::STATUS_EN_TRANSITO,
            'aprobada_por' => User::factory(),
            'despachada_por' => User::factory(),
            'fecha_aprobada' => now(),
            'fecha_despachada' => now(),
            'numero_guia' => 'GUIA-' . $this->faker->numerify('####'),
        ]);
    }

    public function recibida(): static
    {
        return $this->state(fn (array $attributes) => [
            'estado' => TransferHeader::STATUS_RECIBIDA,
            'aprobada_por' => User::factory(),
            'despachada_por' => User::factory(),
            'recibida_por' => User::factory(),
            'fecha_aprobada' => now(),
            'fecha_despachada' => now(),
            'fecha_recibida' => now(),
        ]);
    }

    public function posteada(): static
    {
        return $this->state(fn (array $attributes) => [
            'estado' => TransferHeader::STATUS_POSTEADA,
            'aprobada_por' => User::factory(),
            'despachada_por' => User::factory(),
            'recibida_por' => User::factory(),
            'posteada_por' => User::factory(),
            'fecha_aprobada' => now(),
            'fecha_despachada' => now(),
            'fecha_recibida' => now(),
            'fecha_posteada' => now(),
        ]);
    }
}
