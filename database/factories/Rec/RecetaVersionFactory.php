<?php

namespace Database\Factories\Rec;

use App\Models\Rec\Receta;
use App\Models\Rec\RecetaVersion;
use Illuminate\Database\Eloquent\Factories\Factory;

class RecetaVersionFactory extends Factory
{
    protected $model = RecetaVersion::class;

    public function definition(): array
    {
        return [
            'receta_id' => Receta::factory(),
            'version' => 1,
            'descripcion_cambios' => $this->faker->sentence(),
            'fecha_efectiva' => now()->toDateString(),
            'version_publicada' => false,
            'usuario_publicador' => null,
            'fecha_publicacion' => null,
            'created_at' => now(),
        ];
    }

    public function published(): static
    {
        return $this->state(fn (array $attributes) => [
            'version_publicada' => true,
            'usuario_publicador' => 1,
            'fecha_publicacion' => now(),
        ]);
    }

    public function forRecipe(Receta $receta): static
    {
        return $this->state(fn (array $attributes) => [
            'receta_id' => $receta->id,
        ]);
    }

    public function versionNumber(int $version): static
    {
        return $this->state(fn (array $attributes) => [
            'version' => $version,
        ]);
    }
}
