<?php

namespace Database\Factories\Rec;

use App\Models\Rec\Receta;
use App\Models\Rec\RecipeCostSnapshot;
use Illuminate\Database\Eloquent\Factories\Factory;

class RecipeCostSnapshotFactory extends Factory
{
    protected $model = RecipeCostSnapshot::class;

    public function definition(): array
    {
        return [
            'recipe_id' => Receta::factory(),
            'snapshot_date' => now(),
            'cost_total' => $this->faker->randomFloat(4, 100, 5000),
            'cost_per_portion' => $this->faker->randomFloat(4, 10, 200),
            'portions' => $this->faker->randomFloat(3, 1, 100),
            'cost_breakdown' => [],
            'reason' => RecipeCostSnapshot::REASON_MANUAL,
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
            'snapshot_date' => $date,
            'created_at' => $date,
        ]);
    }

    public function withCost(float $portionCost, float $batchCost, float $yield = 10): static
    {
        return $this->state(fn (array $attributes) => [
            'cost_per_portion' => $portionCost,
            'cost_total' => $batchCost,
            'portions' => $yield,
        ]);
    }

    public function withNotes(string $notes): static
    {
        return $this->state(fn (array $attributes) => [
            'cost_breakdown' => [['notes' => $notes]],
        ]);
    }
}
