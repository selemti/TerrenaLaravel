<?php

namespace Database\Factories\Rec;

use App\Models\Rec\Receta;
use App\Models\Rec\RecipeCostSnapshot;
use App\Models\Rec\RecetaVersion;
use Illuminate\Database\Eloquent\Factories\Factory;

class RecipeCostSnapshotFactory extends Factory
{
    protected $model = RecipeCostSnapshot::class;

    public function definition(): array
    {
        return [
            'recipe_id' => Receta::factory(),
            'recipe_version_id' => RecetaVersion::factory(),
            'snapshot_at' => now(),
            'currency_code' => 'MXN',
            'batch_cost' => $this->faker->randomFloat(6, 100, 5000),
            'portion_cost' => $this->faker->randomFloat(6, 10, 200),
            'batch_size' => $this->faker->randomFloat(6, 1, 50),
            'yield_portions' => $this->faker->randomFloat(6, 1, 100),
            'notes' => $this->faker->optional()->sentence(),
            'created_at' => now(),
        ];
    }

    public function forRecipe(Receta $receta): static
    {
        return $this->state(fn (array $attributes) => [
            'recipe_id' => $receta->id,
        ]);
    }

    public function atDate(string $date): static
    {
        return $this->state(fn (array $attributes) => [
            'snapshot_at' => $date,
            'created_at' => $date,
        ]);
    }

    public function withCost(float $portionCost, float $batchCost, float $yield = 10): static
    {
        return $this->state(fn (array $attributes) => [
            'portion_cost' => $portionCost,
            'batch_cost' => $batchCost,
            'yield_portions' => $yield,
        ]);
    }

    public function withNotes(string $notes): static
    {
        return $this->state(fn (array $attributes) => [
            'notes' => $notes,
        ]);
    }
}
