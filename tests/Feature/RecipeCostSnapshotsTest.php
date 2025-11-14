<?php

namespace Tests\Feature;

use App\Models\Inv\Item;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaDetalle;
use App\Models\Rec\RecetaVersion;
use App\Models\Rec\RecipeCostSnapshot;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class RecipeCostSnapshotsTest extends TestCase
{
    use DatabaseTransactions;

    protected User $user;

    protected Receta $receta;

    protected RecetaVersion $version;

    protected function setUp(): void
    {
        parent::setUp();

        // Get first available user or create test user
        $this->user = User::first();
        if (! $this->user) {
            // Fallback: create minimal user for testing
            $this->user = new User;
            $this->user->id = 1;
            $this->user->email = 'test@test.com';
            $this->user->nombre_completo = 'Test User';
            $this->user->exists = true;
        }

        // Create recipe with version and ingredients (these will be rolled back)
        $this->receta = Receta::factory()->create([
            'porciones_standard' => 10,
        ]);

        $this->version = RecetaVersion::factory()
            ->forRecipe($this->receta)
            ->published()
            ->create();

        // Add some ingredients
        $item1 = Item::factory()->create();
        $item2 = Item::factory()->create();

        RecetaDetalle::factory()->create([
            'receta_id' => $this->receta->id,
            'receta_version_id' => $this->version->id,
            'item_id' => $item1->id,
            'cantidad' => 2.5,
            'costo_unitario' => 45.50,
        ]);

        RecetaDetalle::factory()->create([
            'receta_id' => $this->receta->id,
            'receta_version_id' => $this->version->id,
            'item_id' => $item2->id,
            'cantidad' => 1.0,
            'costo_unitario' => 120.00,
        ]);
    }

    /** @test */
    public function test_can_create_cost_snapshot()
    {
        // Mock stored procedure call
        DB::shouldReceive('connection')->andReturnSelf();
        DB::shouldReceive('statement')->once()->andReturn(true);

        // Create manual snapshot in DB for test
        $snapshot = RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->withCost(23.37, 233.75, 10)
            ->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/recipes/{$this->receta->id}/cost/snapshot", [
                'notes' => 'Test snapshot',
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'ok',
                'message',
                'data' => [
                    'id',
                    'recipe_id',
                    'snapshot_at',
                    'portion_cost',
                    'batch_cost',
                    'yield_portions',
                    'notes',
                ],
            ])
            ->assertJson([
                'ok' => true,
            ]);
    }

    /** @test */
    public function test_can_create_snapshot_with_custom_date()
    {
        DB::shouldReceive('connection')->andReturnSelf();
        DB::shouldReceive('statement')->once()->andReturn(true);

        $snapshot = RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-01-15 10:00:00')
            ->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/recipes/{$this->receta->id}/cost/snapshot", [
                'at' => '2025-01-15 10:00:00',
                'notes' => 'Historical snapshot',
            ]);

        $response->assertStatus(201);
    }

    /** @test */
    public function test_can_get_cost_history()
    {
        // Create multiple snapshots
        RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-01-01 10:00:00')
            ->withCost(20.00, 200.00, 10)
            ->create();

        RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-01-15 10:00:00')
            ->withCost(22.00, 220.00, 10)
            ->create();

        RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-02-01 10:00:00')
            ->withCost(25.00, 250.00, 10)
            ->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$this->receta->id}/cost/history");

        $response->assertOk()
            ->assertJsonStructure([
                'ok',
                'data' => [
                    '*' => [
                        'id',
                        'snapshot_at',
                        'portion_cost',
                        'batch_cost',
                        'yield_portions',
                        'cost_change_pct',
                        'notes',
                    ],
                ],
                'meta' => [
                    'count',
                    'recipe_id',
                ],
            ])
            ->assertJsonCount(3, 'data');
    }

    /** @test */
    public function test_can_filter_history_by_date_range()
    {
        RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-01-01 10:00:00')
            ->create();

        RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-01-15 10:00:00')
            ->create();

        RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-02-01 10:00:00')
            ->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$this->receta->id}/cost/history?from=2025-01-10&to=2025-01-20");

        $response->assertOk()
            ->assertJsonCount(1, 'data');
    }

    /** @test */
    public function test_can_limit_history_results()
    {
        // Create 5 snapshots
        for ($i = 1; $i <= 5; $i++) {
            RecipeCostSnapshot::factory()
                ->forRecipe($this->receta)
                ->atDate("2025-01-{$i} 10:00:00")
                ->create();
        }

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$this->receta->id}/cost/history?limit=3");

        $response->assertOk()
            ->assertJsonCount(3, 'data');
    }

    /** @test */
    public function test_can_compare_two_snapshots()
    {
        $snapshot1 = RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-01-01 10:00:00')
            ->withCost(20.00, 200.00, 10)
            ->create();

        $snapshot2 = RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-02-01 10:00:00')
            ->withCost(25.00, 250.00, 10)
            ->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$this->receta->id}/cost/compare?current_id={$snapshot2->id}&previous_id={$snapshot1->id}");

        $response->assertOk()
            ->assertJsonStructure([
                'ok',
                'data' => [
                    'current' => ['id', 'snapshot_at', 'portion_cost', 'batch_cost'],
                    'previous' => ['id', 'snapshot_at', 'portion_cost', 'batch_cost'],
                    'variance' => [
                        'portion_diff',
                        'portion_pct',
                        'batch_diff',
                        'batch_pct',
                        'days_between',
                    ],
                ],
            ]);

        // Verify variance calculation
        $variance = $response->json('data.variance');
        $this->assertEquals(5.00, $variance['portion_diff']);
        $this->assertEquals(25.00, $variance['portion_pct']); // (25-20)/20 * 100 = 25%
        $this->assertEquals(50.00, $variance['batch_diff']);
        $this->assertEquals(25.00, $variance['batch_pct']);
    }

    /** @test */
    public function test_compare_validates_snapshots_belong_to_recipe()
    {
        $otherReceta = Receta::factory()->create();

        $snapshot1 = RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->create();

        $snapshot2 = RecipeCostSnapshot::factory()
            ->forRecipe($otherReceta)
            ->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$this->receta->id}/cost/compare?current_id={$snapshot2->id}&previous_id={$snapshot1->id}");

        $response->assertStatus(422)
            ->assertJson([
                'ok' => false,
                'message' => 'Los snapshots no pertenecen a la receta especificada',
            ]);
    }

    /** @test */
    public function test_snapshot_endpoints_require_authentication()
    {
        $endpoints = [
            ['method' => 'post', 'uri' => "/api/recipes/{$this->receta->id}/cost/snapshot"],
            ['method' => 'get', 'uri' => "/api/recipes/{$this->receta->id}/cost/history"],
            ['method' => 'get', 'uri' => "/api/recipes/{$this->receta->id}/cost/compare?current_id=1&previous_id=2"],
        ];

        foreach ($endpoints as $endpoint) {
            $response = $this->{$endpoint['method'].'Json'}($endpoint['uri']);
            $response->assertUnauthorized();
        }
    }

    /** @test */
    public function test_cost_change_percentage_attribute_calculates_correctly()
    {
        $snapshot1 = RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-01-01 10:00:00')
            ->withCost(20.00, 200.00, 10)
            ->create();

        $snapshot2 = RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-02-01 10:00:00')
            ->withCost(24.00, 240.00, 10)
            ->create();

        // Snapshot2 should show 20% increase: (24-20)/20 * 100 = 20%
        $this->assertEquals(20.0, $snapshot2->cost_change_percentage);
    }

    /** @test */
    public function test_history_returns_snapshots_in_descending_order()
    {
        RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-01-01 10:00:00')
            ->create();

        RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-02-01 10:00:00')
            ->create();

        RecipeCostSnapshot::factory()
            ->forRecipe($this->receta)
            ->atDate('2025-01-15 10:00:00')
            ->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$this->receta->id}/cost/history");

        $response->assertOk();

        $data = $response->json('data');

        // Should be ordered by snapshot_at DESC
        $this->assertGreaterThan($data[1]['snapshot_at'], $data[0]['snapshot_at']);
        $this->assertGreaterThan($data[2]['snapshot_at'], $data[1]['snapshot_at']);
    }

    /** @test */
    public function test_snapshot_returns_404_for_nonexistent_recipe()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/recipes/NONEXISTENT/cost/snapshot');

        $response->assertNotFound();
    }

    /** @test */
    public function test_history_returns_empty_for_recipe_without_snapshots()
    {
        $newReceta = Receta::factory()->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$newReceta->id}/cost/history");

        $response->assertOk()
            ->assertJsonCount(0, 'data');
    }
}
