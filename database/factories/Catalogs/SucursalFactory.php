<?php

namespace Database\Factories\Catalogs;

use App\Models\Catalogs\Sucursal;
use Illuminate\Database\Eloquent\Factories\Factory;

class SucursalFactory extends Factory
{
    protected $model = Sucursal::class;

    public function definition(): array
    {
        return [
            'nombre' => $this->faker->company() . ' Sucursal',
            'clave' => strtoupper($this->faker->unique()->lexify('SUC-???')),
            'direccion' => $this->faker->address(),
            'telefono' => $this->faker->phoneNumber(),
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
