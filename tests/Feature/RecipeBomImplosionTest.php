<?php

namespace Tests\Feature;

use App\Models\Item;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaDetalle;
use App\Models\Rec\RecetaVersion;
use Illuminate\Support\Facades\DB;
use Tests\Support\InteractsWithRecipeDatabase;
use Tests\TestCase;

class RecipeBomImplosionTest extends TestCase
{
    use InteractsWithRecipeDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->setUpRecipeDatabase();
        $this->withoutMiddleware();
    }

    public function test_it_implodes_simple_recipe_with_only_items(): void
    {
        $this->createCategory('CAT-TEST', 'Harinas');

        $recipe = Receta::factory()->create(['id' => 'REC-SIMPLE', 'nombre_plato' => 'Simple']);
        $version = $this->createVersion($recipe);

        $item1 = Item::factory()->create([
            'id' => 'ITEM-001',
            'nombre' => 'Harina',
            'costo_promedio' => 20,
        ]);

        $item2 = Item::factory()->create([
            'id' => 'ITEM-002',
            'nombre' => 'Azúcar',
            'costo_promedio' => 10,
        ]);

        $this->createDetail($version, $item1, 0.5, 'KG');
        $this->createDetail($version, $item2, 0.2, 'KG');

        $response = $this->getJson('/api/recipes/REC-SIMPLE/bom/implode');

        $response->assertStatus(200)
            ->assertJson([
                'ok' => true,
                'data' => [
                    'recipe_id' => 'REC-SIMPLE',
                    'total_ingredients' => 2,
                ],
            ]);

        $ingredients = $response->json('data.base_ingredients');
        $this->assertCount(2, $ingredients);
        $this->assertEquals('ITEM-001', $ingredients[0]['item_id']);
        $this->assertEquals(0.5, $ingredients[0]['qty']);
    }

    public function test_it_implodes_recipe_with_multiple_items(): void
    {
        $recipe = Receta::factory()->create(['id' => 'REC-HAMBUR', 'nombre_plato' => 'Hamburguesa']);
        $version = $this->createVersion($recipe);

        $meat = Item::factory()->create(['id' => 'ITEM-CAR', 'nombre' => 'Carne', 'costo_promedio' => 80]);
        $cheese = Item::factory()->create(['id' => 'ITEM-QUE', 'nombre' => 'Queso', 'costo_promedio' => 60]);
        $bun = Item::factory()->create(['id' => 'ITEM-PAN', 'nombre' => 'Pan', 'costo_promedio' => 12]);

        $this->createDetail($version, $meat, 0.2, 'KG');
        $this->createDetail($version, $cheese, 0.1, 'KG');
        $this->createDetail($version, $bun, 1, 'PZ');

        $response = $this->getJson('/api/recipes/REC-HAMBUR/bom/implode');

        $response->assertStatus(200)
            ->assertJson([
                'ok' => true,
                'data' => [
                    'recipe_id' => 'REC-HAMBUR',
                    'total_ingredients' => 3,
                ],
            ]);

        $ingredients = collect($response->json('data.base_ingredients'));
        $this->assertTrue($ingredients->contains(fn ($ingredient) => $ingredient['item_id'] === 'ITEM-CAR'));
        $this->assertTrue($ingredients->contains(fn ($ingredient) => $ingredient['item_id'] === 'ITEM-QUE'));
        $this->assertTrue($ingredients->contains(fn ($ingredient) => $ingredient['item_id'] === 'ITEM-PAN'));
    }

    public function test_it_aggregates_duplicate_ingredients(): void
    {
        $recipe = Receta::factory()->create(['id' => 'REC-PIZZA']);
        $version = $this->createVersion($recipe);

        $flour = Item::factory()->create(['id' => 'ITEM-HAR', 'nombre' => 'Harina', 'costo_promedio' => 10]);

        $this->createDetail($version, $flour, 0.5, 'KG');
        $this->createDetail($version, $flour, 0.1, 'KG');

        $response = $this->getJson('/api/recipes/REC-PIZZA/bom/implode');

        $response->assertStatus(200);

        $ingredients = $response->json('data.base_ingredients');
        $this->assertCount(1, $ingredients);
        $this->assertEquals('ITEM-HAR', $ingredients[0]['item_id']);
        $this->assertEquals(0.6, $ingredients[0]['qty']);
    }

    private function createCategory(string $code, string $name): void
    {
        DB::table('selemti.item_categories')->insert([
            'codigo' => $code,
            'nombre' => $name,
            'slug' => strtolower(str_replace(' ', '-', $name)),
            'prefijo' => strtoupper(substr($code, 4, 3) ?: substr($code, -3)),
            'activo' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function createVersion(Receta $recipe): RecetaVersion
    {
        return RecetaVersion::create([
            'receta_id' => $recipe->id,
            'version' => 1,
            'descripcion_cambios' => 'Versión inicial',
            'fecha_efectiva' => now()->toDateString(),
            'version_publicada' => false,
            'created_at' => now(),
        ]);
    }

    private function createDetail(RecetaVersion $version, Item $item, float $qty, string $uom): void
    {
        RecetaDetalle::create([
            'receta_version_id' => $version->id,
            'item_id' => $item->id,
            'cantidad' => $qty,
            'unidad_medida' => $uom,
            'created_at' => now(),
        ]);
    }
}
