<?php

namespace Tests\Feature;

use App\Models\Rec\Receta;
use App\Models\Rec\RecetaDetalle;
use App\Models\Inv\Item;
use App\Models\User;
use App\Models\Catalogs\Unidad;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RecipesApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
    }

    /** @test */
    public function test_can_get_recipe_cost()
    {
        // Crear item para la receta
        $item = Item::factory()->create([
            'nombre' => 'Producto Final',
            'tipo' => 'PRODUCTO',
        ]);

        // Crear receta
        $receta = Receta::factory()->create([
            'item_id' => $item->id,
            'nombre' => 'Receta Test',
            'cantidad_producto' => 1,
            'activa' => true,
        ]);

        // Crear insumos
        $insumo1 = Item::factory()->create([
            'nombre' => 'Insumo 1',
            'tipo' => 'INSUMO',
            'costo_promedio' => 10.00,
        ]);

        $insumo2 = Item::factory()->create([
            'nombre' => 'Insumo 2',
            'tipo' => 'INSUMO',
            'costo_promedio' => 5.00,
        ]);

        // Crear detalles de receta
        RecetaDetalle::factory()->create([
            'receta_id' => $receta->id,
            'item_id' => $insumo1->id,
            'cantidad' => 2, // 2 unidades * $10 = $20
        ]);

        RecetaDetalle::factory()->create([
            'receta_id' => $receta->id,
            'item_id' => $insumo2->id,
            'cantidad' => 4, // 4 unidades * $5 = $20
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$receta->id}/cost");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data' => [
                    'receta_id',
                    'nombre',
                    'ingredientes' => [
                        '*' => ['item_id', 'nombre', 'cantidad', 'costo_unitario', 'costo_total']
                    ],
                    'costo_total',
                    'costo_unitario'
                ],
                'timestamp'
            ])
            ->assertJsonPath('ok', true)
            ->assertJsonPath('data.receta_id', $receta->id);

        // Verificar cálculos
        $data = $response->json('data');
        $this->assertEquals(40.00, $data['costo_total']); // $20 + $20
        $this->assertEquals(40.00, $data['costo_unitario']); // $40 / 1 unidad
    }

    /** @test */
    public function test_recipe_cost_returns_404_for_nonexistent_recipe()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/recipes/99999/cost');

        $response->assertStatus(404)
            ->assertJsonPath('ok', false);
    }

    /** @test */
    public function test_can_implode_bom_single_level()
    {
        // Crear producto final
        $producto = Item::factory()->create(['nombre' => 'Producto Final']);
        $receta = Receta::factory()->create([
            'item_id' => $producto->id,
            'cantidad_producto' => 1,
        ]);

        // Crear insumos directos
        $insumo1 = Item::factory()->create(['nombre' => 'Insumo A']);
        $insumo2 = Item::factory()->create(['nombre' => 'Insumo B']);

        RecetaDetalle::factory()->create([
            'receta_id' => $receta->id,
            'item_id' => $insumo1->id,
            'cantidad' => 2,
        ]);

        RecetaDetalle::factory()->create([
            'receta_id' => $receta->id,
            'item_id' => $insumo2->id,
            'cantidad' => 3,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$receta->id}/bom/implode");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data' => [
                    'receta_id',
                    'bom' => [
                        '*' => ['item_id', 'nombre', 'cantidad', 'nivel']
                    ]
                ],
                'timestamp'
            ])
            ->assertJsonPath('ok', true);

        $bom = $response->json('data.bom');
        $this->assertCount(2, $bom);
    }

    /** @test */
    public function test_can_implode_bom_multi_level()
    {
        // Nivel 0: Producto Final
        $productoFinal = Item::factory()->create(['nombre' => 'Hamburguesa']);
        $recetaFinal = Receta::factory()->create([
            'item_id' => $productoFinal->id,
            'cantidad_producto' => 1,
        ]);

        // Nivel 1: Subproducto (Pan)
        $pan = Item::factory()->create(['nombre' => 'Pan']);
        $recetaPan = Receta::factory()->create([
            'item_id' => $pan->id,
            'cantidad_producto' => 1,
        ]);

        // Nivel 2: Insumo del Pan (Harina)
        $harina = Item::factory()->create(['nombre' => 'Harina']);
        RecetaDetalle::factory()->create([
            'receta_id' => $recetaPan->id,
            'item_id' => $harina->id,
            'cantidad' => 0.5,
        ]);

        // Nivel 1: Insumo directo (Carne)
        $carne = Item::factory()->create(['nombre' => 'Carne']);
        
        // Agregar ingredientes a receta final
        RecetaDetalle::factory()->create([
            'receta_id' => $recetaFinal->id,
            'item_id' => $pan->id,
            'cantidad' => 1,
        ]);

        RecetaDetalle::factory()->create([
            'receta_id' => $recetaFinal->id,
            'item_id' => $carne->id,
            'cantidad' => 0.2,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$recetaFinal->id}/bom/implode");

        $response->assertStatus(200)
            ->assertJsonPath('ok', true);

        $bom = $response->json('data.bom');
        
        // Debe tener 3 items: Pan (nivel 1), Carne (nivel 1), Harina (nivel 2)
        $this->assertGreaterThanOrEqual(2, count($bom));

        // Verificar que hay items de diferentes niveles
        $niveles = array_column($bom, 'nivel');
        $this->assertContains(1, $niveles); // Pan y Carne
    }

    /** @test */
    public function test_bom_implosion_prevents_infinite_recursion()
    {
        // Crear ciclo A → B → A
        $itemA = Item::factory()->create(['nombre' => 'Item A']);
        $itemB = Item::factory()->create(['nombre' => 'Item B']);

        $recetaA = Receta::factory()->create(['item_id' => $itemA->id]);
        $recetaB = Receta::factory()->create(['item_id' => $itemB->id]);

        // A depende de B
        RecetaDetalle::factory()->create([
            'receta_id' => $recetaA->id,
            'item_id' => $itemB->id,
            'cantidad' => 1,
        ]);

        // B depende de A (crear ciclo)
        RecetaDetalle::factory()->create([
            'receta_id' => $recetaB->id,
            'item_id' => $itemA->id,
            'cantidad' => 1,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$recetaA->id}/bom/implode");

        // Debe manejar el ciclo sin error (max 10 niveles)
        $response->assertStatus(200)
            ->assertJsonPath('ok', true);

        $bom = $response->json('data.bom');
        
        // Verificar que no hay más de 10 niveles de recursión
        $niveles = array_column($bom, 'nivel');
        $maxNivel = !empty($niveles) ? max($niveles) : 0;
        $this->assertLessThanOrEqual(10, $maxNivel);
    }

    /** @test */
    public function test_bom_implosion_returns_404_for_nonexistent_recipe()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/recipes/99999/bom/implode');

        $response->assertStatus(404)
            ->assertJsonPath('ok', false);
    }

    /** @test */
    public function test_recipe_cost_handles_recipe_without_ingredients()
    {
        $item = Item::factory()->create();
        $receta = Receta::factory()->create([
            'item_id' => $item->id,
            'cantidad_producto' => 1,
        ]);

        // No crear detalles (receta vacía)

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$receta->id}/cost");

        $response->assertStatus(200)
            ->assertJsonPath('ok', true)
            ->assertJsonPath('data.costo_total', 0)
            ->assertJsonPath('data.costo_unitario', 0);
    }

    /** @test */
    public function test_recipe_cost_calculates_correctly_for_multiple_units()
    {
        $item = Item::factory()->create();
        $receta = Receta::factory()->create([
            'item_id' => $item->id,
            'cantidad_producto' => 10, // Produce 10 unidades
        ]);

        $insumo = Item::factory()->create(['costo_promedio' => 50.00]);

        RecetaDetalle::factory()->create([
            'receta_id' => $receta->id,
            'item_id' => $insumo->id,
            'cantidad' => 5, // 5 * $50 = $250 total
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$receta->id}/cost");

        $response->assertStatus(200);

        $data = $response->json('data');
        $this->assertEquals(250.00, $data['costo_total']);
        $this->assertEquals(25.00, $data['costo_unitario']); // $250 / 10 unidades
    }

    /** @test */
    public function test_recipe_endpoints_require_authentication()
    {
        $receta = Receta::factory()->create();

        $endpoints = [
            "/api/recipes/{$receta->id}/cost",
            "/api/recipes/{$receta->id}/bom/implode",
        ];

        foreach ($endpoints as $endpoint) {
            $response = $this->getJson($endpoint);
            $response->assertStatus(401); // Unauthorized
        }
    }

    /** @test */
    public function test_recipe_endpoints_return_consistent_response_structure()
    {
        $receta = Receta::factory()->create();

        $endpoints = [
            "/api/recipes/{$receta->id}/cost",
            "/api/recipes/{$receta->id}/bom/implode",
        ];

        foreach ($endpoints as $endpoint) {
            $response = $this->actingAs($this->user, 'sanctum')
                ->getJson($endpoint);

            $response->assertStatus(200)
                ->assertJsonStructure(['ok', 'data', 'timestamp'])
                ->assertJsonPath('ok', true);
        }
    }

    /** @test */
    public function test_bom_implosion_aggregates_duplicate_ingredients()
    {
        // Producto que usa el mismo ingrediente en múltiples niveles
        $producto = Item::factory()->create(['nombre' => 'Pizza']);
        $receta = Receta::factory()->create([
            'item_id' => $producto->id,
            'cantidad_producto' => 1,
        ]);

        $queso = Item::factory()->create(['nombre' => 'Queso']);

        // Usar queso 2 veces en la receta (directamente)
        RecetaDetalle::factory()->create([
            'receta_id' => $receta->id,
            'item_id' => $queso->id,
            'cantidad' => 100, // gramos
        ]);

        RecetaDetalle::factory()->create([
            'receta_id' => $receta->id,
            'item_id' => $queso->id,
            'cantidad' => 50, // más gramos
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/recipes/{$receta->id}/bom/implode");

        $response->assertStatus(200);

        $bom = $response->json('data.bom');
        
        // Debe agregar las cantidades (100 + 50 = 150)
        $quesoItem = collect($bom)->firstWhere('nombre', 'Queso');
        $this->assertNotNull($quesoItem);
        $this->assertEquals(150, $quesoItem['cantidad']);
    }
}
