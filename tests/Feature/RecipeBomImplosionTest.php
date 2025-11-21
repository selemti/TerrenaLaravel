<?php

namespace Tests\Feature;

use App\Models\Item;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaDetalle;
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
        $categoryId = DB::table('item_categories')->insertGetId([
            'nombre' => 'Harinas',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $recipe = Receta::factory()->create(['id' => 'REC-SIMPLE', 'nombre_plato' => 'Simple']);

        $item1 = Item::factory()->create([
            'id' => 'ITEM-001',
            'nombre' => 'Harina',
            'categoria_id' => $categoryId,
            'costo_promedio' => 20,
        ]);

        $item2 = Item::factory()->create([
            'id' => 'ITEM-002',
            'nombre' => 'Azúcar',
            'categoria_id' => $categoryId,
            'costo_promedio' => 10,
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-SIMPLE',
            'item_id' => 'ITEM-001',
            'cantidad' => 0.5,
            'unidad_id' => 'KG',
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-SIMPLE',
            'item_id' => 'ITEM-002',
            'cantidad' => 0.2,
            'unidad_id' => 'KG',
        ]);

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

    public function test_it_implodes_complex_recipe_with_subrecipes(): void
    {
        $bread = Receta::factory()->create(['id' => 'REC-PAN', 'nombre_plato' => 'Pan Casero']);
        $main = Receta::factory()->create(['id' => 'REC-HAMBUR', 'nombre_plato' => 'Hamburguesa']);

        $flour = Item::factory()->create(['id' => 'ITEM-HAR', 'nombre' => 'Harina', 'costo_promedio' => 15]);
        $butter = Item::factory()->create(['id' => 'ITEM-MAN', 'nombre' => 'Mantequilla', 'costo_promedio' => 25]);
        $meat = Item::factory()->create(['id' => 'ITEM-CAR', 'nombre' => 'Carne', 'costo_promedio' => 80]);
        $cheese = Item::factory()->create(['id' => 'ITEM-QUE', 'nombre' => 'Queso', 'costo_promedio' => 60]);

        RecetaDetalle::create([
            'receta_id' => 'REC-PAN',
            'item_id' => 'ITEM-HAR',
            'cantidad' => 0.5,
            'unidad_id' => 'KG',
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-PAN',
            'item_id' => 'ITEM-MAN',
            'cantidad' => 0.05,
            'unidad_id' => 'KG',
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-HAMBUR',
            'receta_id_ingrediente' => 'REC-PAN',
            'cantidad' => 1,
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-HAMBUR',
            'item_id' => 'ITEM-CAR',
            'cantidad' => 0.2,
            'unidad_id' => 'KG',
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-HAMBUR',
            'item_id' => 'ITEM-QUE',
            'cantidad' => 0.1,
            'unidad_id' => 'KG',
        ]);

        $response = $this->getJson('/api/recipes/REC-HAMBUR/bom/implode');

        $response->assertStatus(200)
            ->assertJson([
                'ok' => true,
                'data' => [
                    'recipe_id' => 'REC-HAMBUR',
                    'total_ingredients' => 4,
                ],
            ]);

        $ingredients = collect($response->json('data.base_ingredients'));
        $this->assertTrue($ingredients->contains(fn ($ingredient) => $ingredient['item_id'] === 'ITEM-HAR'));
        $this->assertTrue($ingredients->contains(fn ($ingredient) => $ingredient['item_id'] === 'ITEM-MAN'));
        $this->assertTrue($ingredients->contains(fn ($ingredient) => $ingredient['item_id'] === 'ITEM-CAR'));
        $this->assertTrue($ingredients->contains(fn ($ingredient) => $ingredient['item_id'] === 'ITEM-QUE'));
    }

    public function test_it_aggregates_duplicate_ingredients_from_multiple_subrecipes(): void
    {
        $masa = Receta::factory()->create(['id' => 'REC-MASA']);
        $salsa = Receta::factory()->create(['id' => 'REC-SALSA']);
        $pizza = Receta::factory()->create(['id' => 'REC-PIZZA']);

        $harina = Item::factory()->create(['id' => 'ITEM-HAR', 'nombre' => 'Harina', 'costo_promedio' => 10]);

        RecetaDetalle::create([
            'receta_id' => 'REC-MASA',
            'item_id' => 'ITEM-HAR',
            'cantidad' => 0.5,
            'unidad_id' => 'KG',
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-SALSA',
            'item_id' => 'ITEM-HAR',
            'cantidad' => 0.1,
            'unidad_id' => 'KG',
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-PIZZA',
            'receta_id_ingrediente' => 'REC-MASA',
            'cantidad' => 1,
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-PIZZA',
            'receta_id_ingrediente' => 'REC-SALSA',
            'cantidad' => 1,
        ]);

        $response = $this->getJson('/api/recipes/REC-PIZZA/bom/implode');

        $response->assertStatus(200);

        $ingredients = $response->json('data.base_ingredients');
        $this->assertCount(1, $ingredients);
        $this->assertEquals('ITEM-HAR', $ingredients[0]['item_id']);
        $this->assertEquals(0.6, $ingredients[0]['qty']);
    }
}
