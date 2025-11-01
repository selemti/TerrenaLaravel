<?php

namespace Database\Factories\Catalogs;

use App\Models\Catalogs\Almacen;
use Illuminate\Database\Eloquent\Factories\Factory;

class AlmacenFactory extends Factory
{
    protected $model = Almacen::class;

    public function definition(): array
    {
        return [
            'nombre' => $this->faker->company() . ' Almacén',
            'clave' => strtoupper($this->faker->unique()->lexify('ALM-???')),
            'sucursal_id' => 1,
            'tipo' => $this->faker->randomElement(['PRINCIPAL', 'SECUNDARIO', 'TRANSITO']),
            'activo' => true,
            'direccion' => $this->faker->address(),
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
