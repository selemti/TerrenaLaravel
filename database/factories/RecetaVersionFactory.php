<?php

namespace Database\Factories;

use App\Models\Rec\RecetaVersion;
use App\Models\Rec\Receta;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Rec\RecetaVersion>
 */
class RecetaVersionFactory extends Factory
{
    protected $model = RecetaVersion::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'receta_id' => Receta::factory(),
            'version' => 1,
            'descripcion_cambios' => $this->faker->optional()->sentence(),
            'fecha_efectiva' => now(),
            'version_publicada' => false,
            'usuario_publicador' => null,
            'fecha_publicacion' => null,
            'created_at' => now(),
        ];
    }
}
