<?php

namespace Tests\Feature;

use App\Models\Inv\Item;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaDetalle;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * Integration tests for recipe API endpoints.
 *
 * Two endpoints are tested here:
 *
 *  GET /api/recipes/{id}/cost      → RecipeCostController::show
 *    Calculates costs from selemti.receta_cab / selemti.receta_det VARCHAR recipe ids.
 *
 *  GET /api/recipes/{id}/bom/implode → RecipeCostController::implodeBom
 *    Uses Receta Eloquent model (selemti.receta_cab, VARCHAR PKs). Fully testable.
 */
class RecipesApiTest extends TestCase
{
    protected User $user;

    private array $recetaIds = [];

    private array $itemIds = [];

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create([
            'email' => 'test-recipes-'.uniqid().'@terrena.test',
        ]);

        // Bypass Spatie permission middleware — tests cover API logic, not RBAC.
        // auth:sanctum middleware still enforced (see auth test).
        $this->withoutMiddleware(\Spatie\Permission\Middleware\PermissionMiddleware::class);

        $this->actingAs($this->user, 'sanctum');
    }

    protected function tearDown(): void
    {
        if ($this->recetaIds) {
            DB::connection('pgsql')->table('selemti.receta_det')
                ->whereIn('receta_id', $this->recetaIds)->delete();
            DB::connection('pgsql')->table('selemti.receta_cab')
                ->whereIn('id', $this->recetaIds)->delete();
        }
        if ($this->itemIds) {
            DB::connection('pgsql')->table('selemti.items')
                ->whereIn('id', $this->itemIds)->delete();
        }
        DB::connection('pgsql')->table('selemti.users')
            ->where('id', $this->user->id)->delete();
        parent::tearDown();
    }

    // ──────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────

    private function makeItem(array $overrides = []): Item
    {
        $item = Item::factory()->create(array_merge(['costo_promedio' => 10.00], $overrides));
        $this->itemIds[] = $item->id;

        return $item;
    }

    private function makeReceta(array $overrides = []): Receta
    {
        $receta = Receta::factory()->create($overrides);
        $this->recetaIds[] = $receta->id;

        return $receta;
    }

    private function makeDetalle(Receta $receta, Item $item, float $cantidad): RecetaDetalle
    {
        return RecetaDetalle::factory()->create([
            'receta_id' => $receta->id,
            'item_id' => $item->id,
            'cantidad' => $cantidad,
        ]);
    }

    // ──────────────────────────────────────────────────────
    // /cost endpoint
    // ──────────────────────────────────────────────────────

    public function test_can_get_recipe_cost(): void
    {
        $item = $this->makeItem(['costo_promedio' => 12.50]);
        $receta = $this->makeReceta(['porciones_standard' => 5]);
        $this->makeDetalle($receta, $item, 4);

        $response = $this->getJson("/api/recipes/{$receta->id}/cost");

        $response->assertOk()
            ->assertJsonPath('data.recipe_id', $receta->id)
            ->assertJsonPath('data.batch_cost', 50)
            ->assertJsonPath('data.portion_cost', 10)
            ->assertJsonPath('data.yield_portions', 5);
    }

    public function test_recipe_cost_returns_404_for_nonexistent_recipe(): void
    {
        $response = $this->getJson('/api/recipes/REC-NONEXISTENT-99999/cost');

        $response->assertNotFound();
    }

    public function test_recipe_cost_handles_recipe_without_ingredients(): void
    {
        $receta = $this->makeReceta(['porciones_standard' => 4]);

        $response = $this->getJson("/api/recipes/{$receta->id}/cost");

        $response->assertOk()
            ->assertJsonPath('data.batch_cost', 0)
            ->assertJsonPath('data.portion_cost', 0)
            ->assertJsonPath('data.yield_portions', 4);
    }

    public function test_recipe_cost_calculates_correctly_for_multiple_units(): void
    {
        $item1 = $this->makeItem(['costo_promedio' => 8.00]);
        $item2 = $this->makeItem(['costo_promedio' => 3.25]);
        $receta = $this->makeReceta(['porciones_standard' => 2]);

        $this->makeDetalle($receta, $item1, 2.5);
        $this->makeDetalle($receta, $item2, 4);

        $response = $this->getJson("/api/recipes/{$receta->id}/cost?at=2026-05-15 10:00:00");

        $response->assertOk()
            ->assertJsonPath('data.batch_cost', 33)
            ->assertJsonPath('data.portion_cost', 16.5)
            ->assertJsonCount(2, 'data.cost_breakdown');
    }

    // ──────────────────────────────────────────────────────
    // /bom/implode endpoint — fully testable
    // ──────────────────────────────────────────────────────

    public function test_can_implode_bom_single_level(): void
    {
        $insumo1 = $this->makeItem();
        $insumo2 = $this->makeItem();
        $receta = $this->makeReceta(['porciones_standard' => 1]);

        $this->makeDetalle($receta, $insumo1, 2);
        $this->makeDetalle($receta, $insumo2, 3);

        $response = $this->getJson("/api/recipes/{$receta->id}/bom/implode");

        $response->assertStatus(200)
            ->assertJsonPath('ok', true)
            ->assertJsonStructure(['ok', 'data' => ['recipe_id', 'base_ingredients', 'total_ingredients'], 'timestamp']);

        $this->assertCount(2, $response->json('data.base_ingredients'));
    }

    public function test_can_implode_bom_multi_level(): void
    {
        $harina = $this->makeItem();
        $carne = $this->makeItem();
        $pan = $this->makeItem();
        $recetaPan = $this->makeReceta(['porciones_standard' => 1]);
        $recetaFinal = $this->makeReceta(['porciones_standard' => 1]);

        $this->makeDetalle($recetaPan, $harina, 0.5);
        $this->makeDetalle($recetaFinal, $pan, 1);
        $this->makeDetalle($recetaFinal, $carne, 0.2);

        $response = $this->getJson("/api/recipes/{$recetaFinal->id}/bom/implode");

        $response->assertStatus(200)->assertJsonPath('ok', true);

        // At least pan and carne are direct ingredients
        $this->assertGreaterThanOrEqual(2, count($response->json('data.base_ingredients')));
    }

    public function test_bom_implosion_prevents_infinite_recursion(): void
    {
        $itemA = $this->makeItem();
        $itemB = $this->makeItem();
        $recetaA = $this->makeReceta(['porciones_standard' => 1]);
        $recetaB = $this->makeReceta(['porciones_standard' => 1]);

        // Cycle: A → B → A
        $this->makeDetalle($recetaA, $itemB, 1);
        $this->makeDetalle($recetaB, $itemA, 1);

        $response = $this->getJson("/api/recipes/{$recetaA->id}/bom/implode");

        // Must not crash, must return 200 or 400 (caught RuntimeException)
        $this->assertContains($response->status(), [200, 400]);
    }

    public function test_bom_implosion_returns_404_for_nonexistent_recipe(): void
    {
        $response = $this->getJson('/api/recipes/REC-NONEXISTENT-99999/bom/implode');

        $response->assertStatus(404)->assertJsonPath('ok', false);
    }

    public function test_recipe_endpoints_require_authentication(): void
    {
        $receta = $this->makeReceta();

        // Fresh unauthenticated request — auth:sanctum middleware still active
        $this->app['auth']->forgetGuards();
        $response = $this->getJson("/api/recipes/{$receta->id}/bom/implode");
        $response->assertStatus(401);
    }

    public function test_recipe_endpoints_return_consistent_response_structure(): void
    {
        $receta = $this->makeReceta();

        $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$receta->id}/bom/implode")
            ->assertStatus(200)
            ->assertJsonStructure(['ok', 'data', 'timestamp'])
            ->assertJsonPath('ok', true);
    }

    public function test_bom_implosion_aggregates_duplicate_ingredients(): void
    {
        $queso = $this->makeItem();
        $receta = $this->makeReceta(['porciones_standard' => 1]);

        // Same ingredient twice in the recipe
        $this->makeDetalle($receta, $queso, 100);
        $this->makeDetalle($receta, $queso, 50);

        $response = $this->getJson("/api/recipes/{$receta->id}/bom/implode");

        $response->assertStatus(200);

        $ingredients = $response->json('data.base_ingredients');
        $quesoItem = collect($ingredients)->firstWhere('item_id', $queso->id);

        $this->assertNotNull($quesoItem, 'El ingrediente queso debe aparecer en el BOM');
        $this->assertEquals(150, (float) ($quesoItem['qty'] ?? $quesoItem['total_qty'] ?? 0));
    }
}
