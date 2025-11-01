<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaVersion;
use App\Models\Rec\RecetaDetalle;
use App\Models\Inv\Item;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithoutMiddleware;

class RecipeBomImplosionTest extends TestCase
{
    use WithoutMiddleware; // Skip middleware for testing

    /**
     * Test Case 1: Receta simple (solo ingredientes base)
     * 
     * @return void
     */
    public function test_simple_recipe_returns_base_ingredients(): void
    {
        // Arrange: Crear receta simple con 2 ingredientes base
        $receta = Receta::factory()->create([
            'id' => 'REC-TEST-001',
            'nombre_plato' => 'Ensalada Simple',
        ]);

        $version = RecetaVersion::factory()->create([
            'receta_id' => $receta->id,
            'version' => 1,
            'version_publicada' => true,
        ]);

        // Ingrediente 1: Lechuga
        RecetaDetalle::factory()->create([
            'receta_version_id' => $version->id,
            'item_id' => 'ITEM-001',
            'cantidad' => 100,
            'unidad_medida' => 'GR',
        ]);

        // Ingrediente 2: Tomate
        RecetaDetalle::factory()->create([
            'receta_version_id' => $version->id,
            'item_id' => 'ITEM-002',
            'cantidad' => 50,
            'unidad_medida' => 'GR',
        ]);

        // Act: Llamar al endpoint BOM Implode
        $response = $this->getJson("/api/recipes/{$receta->id}/bom/implode");

        // Assert
        $response->assertStatus(200)
                 ->assertJson([
                     'ok' => true,
                     'recipe_id' => 'REC-TEST-001',
                     'total_ingredients' => 2,
                     'aggregated' => true,
                 ]);

        $baseIngredients = $response->json('base_ingredients');
        
        $this->assertCount(2, $baseIngredients);
        
        // Verificar que contiene los ingredientes esperados
        $itemIds = collect($baseIngredients)->pluck('item_id')->toArray();
        $this->assertContains('ITEM-001', $itemIds);
        $this->assertContains('ITEM-002', $itemIds);
    }

    /**
     * Test Case 2: Receta compuesta (con sub-recetas)
     * 
     * @return void
     */
    public function test_complex_recipe_implodes_subrecipes_recursively(): void
    {
        // Arrange: Crear receta compuesta
        
        // Sub-receta: Salsa (REC-SUB-001)
        $subReceta = Receta::factory()->create([
            'id' => 'REC-SUB-001',
            'nombre_plato' => 'Salsa Básica',
        ]);

        $subVersion = RecetaVersion::factory()->create([
            'receta_id' => $subReceta->id,
            'version' => 1,
            'version_publicada' => true,
        ]);

        // Ingredientes de la sub-receta
        RecetaDetalle::factory()->create([
            'receta_version_id' => $subVersion->id,
            'item_id' => 'ITEM-TOMATE',
            'cantidad' => 200, // 200 gr tomate
            'unidad_medida' => 'GR',
        ]);

        RecetaDetalle::factory()->create([
            'receta_version_id' => $subVersion->id,
            'item_id' => 'ITEM-CEBOLLA',
            'cantidad' => 50, // 50 gr cebolla
            'unidad_medida' => 'GR',
        ]);

        // Receta principal: Pasta con Salsa (REC-MAIN-001)
        $recetaPrincipal = Receta::factory()->create([
            'id' => 'REC-MAIN-001',
            'nombre_plato' => 'Pasta con Salsa',
        ]);

        $versionPrincipal = RecetaVersion::factory()->create([
            'receta_id' => $recetaPrincipal->id,
            'version' => 1,
            'version_publicada' => true,
        ]);

        // Ingrediente 1: Pasta (item base)
        RecetaDetalle::factory()->create([
            'receta_version_id' => $versionPrincipal->id,
            'item_id' => 'ITEM-PASTA',
            'cantidad' => 100,
            'unidad_medida' => 'GR',
        ]);

        // Ingrediente 2: Salsa (sub-receta)
        RecetaDetalle::factory()->create([
            'receta_version_id' => $versionPrincipal->id,
            'item_id' => 'REC-SUB-001', // ¡Es una sub-receta!
            'cantidad' => 1, // 1 porción de salsa
            'unidad_medida' => 'PORCION',
        ]);

        // Act: Llamar al endpoint BOM Implode
        $response = $this->getJson("/api/recipes/{$recetaPrincipal->id}/bom/implode");

        // Assert
        $response->assertStatus(200)
                 ->assertJson([
                     'ok' => true,
                     'recipe_id' => 'REC-MAIN-001',
                     'total_ingredients' => 3, // Pasta + Tomate + Cebolla (salsa implodida)
                     'aggregated' => true,
                 ]);

        $baseIngredients = $response->json('base_ingredients');
        
        $this->assertCount(3, $baseIngredients);
        
        // Verificar que NO contiene la sub-receta, solo ingredientes base
        $itemIds = collect($baseIngredients)->pluck('item_id')->toArray();
        $this->assertContains('ITEM-PASTA', $itemIds);
        $this->assertContains('ITEM-TOMATE', $itemIds);
        $this->assertContains('ITEM-CEBOLLA', $itemIds);
        $this->assertNotContains('REC-SUB-001', $itemIds); // Sub-receta NO debe aparecer
    }

    /**
     * Test Case 3: Ingredientes duplicados deben agregarse
     * 
     * @return void
     */
    public function test_duplicate_ingredients_are_aggregated(): void
    {
        // Arrange: Crear receta con mismo ingrediente en 2 sub-recetas
        
        // Sub-receta 1: Salsa Roja
        $subReceta1 = Receta::factory()->create([
            'id' => 'REC-SALSA-ROJA',
            'nombre_plato' => 'Salsa Roja',
        ]);

        $subVersion1 = RecetaVersion::factory()->create([
            'receta_id' => $subReceta1->id,
            'version' => 1,
            'version_publicada' => true,
        ]);

        RecetaDetalle::factory()->create([
            'receta_version_id' => $subVersion1->id,
            'item_id' => 'ITEM-TOMATE',
            'cantidad' => 100, // 100 gr tomate
            'unidad_medida' => 'GR',
        ]);

        // Sub-receta 2: Salsa Verde
        $subReceta2 = Receta::factory()->create([
            'id' => 'REC-SALSA-VERDE',
            'nombre_plato' => 'Salsa Verde',
        ]);

        $subVersion2 = RecetaVersion::factory()->create([
            'receta_id' => $subReceta2->id,
            'version' => 1,
            'version_publicada' => true,
        ]);

        RecetaDetalle::factory()->create([
            'receta_version_id' => $subVersion2->id,
            'item_id' => 'ITEM-TOMATE', // ¡Mismo tomate!
            'cantidad' => 50, // 50 gr tomate
            'unidad_medida' => 'GR',
        ]);

        // Receta principal con ambas salsas
        $recetaPrincipal = Receta::factory()->create([
            'id' => 'REC-COMBO',
            'nombre_plato' => 'Combo Salsas',
        ]);

        $versionPrincipal = RecetaVersion::factory()->create([
            'receta_id' => $recetaPrincipal->id,
            'version' => 1,
            'version_publicada' => true,
        ]);

        RecetaDetalle::factory()->create([
            'receta_version_id' => $versionPrincipal->id,
            'item_id' => 'REC-SALSA-ROJA',
            'cantidad' => 1,
            'unidad_medida' => 'PORCION',
        ]);

        RecetaDetalle::factory()->create([
            'receta_version_id' => $versionPrincipal->id,
            'item_id' => 'REC-SALSA-VERDE',
            'cantidad' => 1,
            'unidad_medida' => 'PORCION',
        ]);

        // Act
        $response = $this->getJson("/api/recipes/{$recetaPrincipal->id}/bom/implode");

        // Assert
        $response->assertStatus(200);

        $baseIngredients = $response->json('base_ingredients');
        
        // Solo debe haber 1 item (tomate), pero con cantidad agregada
        $this->assertCount(1, $baseIngredients);
        
        $tomate = collect($baseIngredients)->firstWhere('item_id', 'ITEM-TOMATE');
        $this->assertNotNull($tomate);
        
        // Cantidad total debe ser 100 + 50 = 150
        $this->assertEquals(150, $tomate['total_qty']);
    }

    /**
     * Test Case 4: Protección contra loops infinitos
     * 
     * @return void
     */
    public function test_infinite_loop_protection(): void
    {
        // Arrange: Crear recetas con referencia circular (A -> B -> A)
        
        $recetaA = Receta::factory()->create(['id' => 'REC-LOOP-A']);
        $versionA = RecetaVersion::factory()->create([
            'receta_id' => 'REC-LOOP-A',
            'version_publicada' => true,
        ]);

        $recetaB = Receta::factory()->create(['id' => 'REC-LOOP-B']);
        $versionB = RecetaVersion::factory()->create([
            'receta_id' => 'REC-LOOP-B',
            'version_publicada' => true,
        ]);

        // A usa B como ingrediente
        RecetaDetalle::factory()->create([
            'receta_version_id' => $versionA->id,
            'item_id' => 'REC-LOOP-B',
            'cantidad' => 1,
        ]);

        // B usa A como ingrediente (loop!)
        RecetaDetalle::factory()->create([
            'receta_version_id' => $versionB->id,
            'item_id' => 'REC-LOOP-A',
            'cantidad' => 1,
        ]);

        // Act & Assert
        $response = $this->getJson("/api/recipes/REC-LOOP-A/bom/implode");

        // Debe detectar el loop y no crashear
        // Puede retornar error 400 o manejar gracefully
        $this->assertTrue($response->status() === 200 || $response->status() === 400);
    }
}
