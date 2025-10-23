<?php

namespace Tests\Unit\Costing;

use App\Services\Costing\RecipeCostingService;
use PHPUnit\Framework\Attributes\CoversClass;
use Tests\TestCase;

#[CoversClass(RecipeCostingService::class)]
class RecipeCostingServiceTest extends TestCase
{
    public function test_calculate_combines_cost_breakdown(): void
    {
        $material = [
            'batch_cost' => 120.0,
            'portion_cost' => 12.0,
            'yield_portions' => 10.0,
            'details' => [],
        ];

        $labor = [
            'batch_cost' => 30.0,
            'steps' => [],
            'total_minutes' => 120.0,
        ];

        $overhead = [
            'batch_cost' => 15.0,
            'items' => [],
        ];

        $service = new class($material, $labor, $overhead) extends RecipeCostingService {
            public function __construct(private array $material, private array $labor, private array $overhead)
            {
                parent::__construct('pgsql');
            }

            protected function resolveMaterialCost(int $recipeId, string $at): array
            {
                return $this->material;
            }

            protected function resolveLaborCost(int $recipeId, string $at, array $mpCost): array
            {
                return $this->labor;
            }

            protected function resolveOverheadCost(int $recipeId, string $at, array $mpCost, array $laborCost): array
            {
                return $this->overhead;
            }
        };

        $result = $service->calculate(101, now());

        $this->assertSame(165.0, $result['total_batch_cost']);
        $this->assertSame(16.5, $result['portion_cost']);
        $this->assertSame(10.0, $result['yield_portions']);
        $this->assertSame($material, $result['material']);
        $this->assertSame($labor, $result['labor']);
        $this->assertSame($overhead, $result['overhead']);
    }

    public function test_calculate_handles_zero_yield(): void
    {
        $service = new class extends RecipeCostingService {
            protected function resolveMaterialCost(int $recipeId, string $at): array
            {
                return [
                    'batch_cost' => 0.0,
                    'portion_cost' => 0.0,
                    'yield_portions' => 0.0,
                    'details' => [],
                ];
            }

            protected function resolveLaborCost(int $recipeId, string $at, array $mpCost): array
            {
                return ['batch_cost' => 10.0, 'steps' => [], 'total_minutes' => 0.0];
            }

            protected function resolveOverheadCost(int $recipeId, string $at, array $mpCost, array $laborCost): array
            {
                return ['batch_cost' => 5.0, 'items' => []];
            }
        };

        $result = $service->calculate(5, now());

        $this->assertSame(15.0, $result['total_batch_cost']);
        $this->assertSame(0.0, $result['portion_cost']);
        $this->assertSame(0.0, $result['yield_portions']);
    }
}
