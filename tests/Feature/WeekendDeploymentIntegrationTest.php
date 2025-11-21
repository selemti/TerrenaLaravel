<?php

namespace Tests\Feature;

use App\Models\Item;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaDetalle;
use App\Models\Rec\RecipeCostSnapshot;
use App\Services\Recipes\RecipeCostSnapshotService;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Support\InteractsWithRecipeDatabase;
use Tests\TestCase;

class WeekendDeploymentIntegrationTest extends TestCase
{
    use InteractsWithRecipeDatabase;

    private RecipeCostSnapshotService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $this->setUpRecipeDatabase();
        $this->withoutMiddleware();

        $this->service = app(RecipeCostSnapshotService::class);

        DB::table('users')->insert([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function test_it_can_calculate_recipe_cost_via_endpoint(): void
    {
        $recipe = $this->createRecipeWithItems('REC-INT-001', [
            ['id' => 'ITEM-A', 'qty' => 1, 'cost' => 40],
            ['id' => 'ITEM-B', 'qty' => 0.5, 'cost' => 20],
        ]);

        $response = $this->getJson('/api/recipes/REC-INT-001/cost');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'recipe_id',
                    'cost_total',
                    'cost_per_portion',
                ],
                'requested_at',
            ]);

        $data = $response->json('data');
        $this->assertEquals('REC-INT-001', $data['recipe_id']);
        $this->assertGreaterThan(0, $data['cost_total']);
    }

    public function test_it_can_create_snapshot_end_to_end(): void
    {
        $this->createRecipeWithItems('REC-INT-002', [
            ['id' => 'ITEM-C', 'qty' => 2, 'cost' => 15],
        ], portions: 2);

        $snapshot = $this->service->createSnapshot(
            'REC-INT-002',
            RecipeCostSnapshot::REASON_MANUAL,
            1,
            Carbon::parse('2025-11-01 09:00:00')
        );

        $this->assertNotNull($snapshot->id);

        $costData = $this->service->getCostAtDate(
            'REC-INT-002',
            Carbon::parse('2025-11-01 10:00:00')
        );

        $this->assertTrue($costData['from_snapshot']);
        $this->assertEquals('REC-INT-002', $costData['recipe_id']);
    }

    public function test_it_can_implode_bom_via_endpoint(): void
    {
        $this->createRecipeWithItems('REC-BOM-001', [
            ['id' => 'ITEM-X', 'qty' => 1.5, 'cost' => 25],
            ['id' => 'ITEM-Y', 'qty' => 0.5, 'cost' => 12],
        ]);

        $response = $this->getJson('/api/recipes/REC-BOM-001/bom/implode');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data' => [
                    'recipe_id',
                    'base_ingredients' => [
                        ['item_id', 'qty', 'uom'],
                    ],
                    'total_ingredients',
                ],
                'timestamp',
            ]);

        $this->assertEquals(2, $response->json('data.total_ingredients'));
    }

    private function createRecipeWithItems(string $recipeId, array $items, int $portions = 1): Receta
    {
        $recipe = Receta::factory()->create([
            'id' => $recipeId,
            'porciones_standard' => $portions,
        ]);

        foreach ($items as $index => $itemConfig) {
            $item = Item::factory()->create([
                'id' => $itemConfig['id'],
                'nombre' => 'Item ' . $index,
                'costo_promedio' => $itemConfig['cost'],
            ]);

            RecetaDetalle::create([
                'receta_id' => $recipeId,
                'item_id' => $item->id,
                'cantidad' => $itemConfig['qty'],
                'unidad_id' => 'PZ',
            ]);
        }

        return $recipe;
    }
}
