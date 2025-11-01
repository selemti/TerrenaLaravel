<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\WithoutMiddleware;

class RecipeBomImplosionManualTest extends TestCase
{
    use WithoutMiddleware;

    /**
     * Test manual del endpoint BOM Implosion con recetas reales
     * Este test asume que hay recetas en la BD
     * 
     * @return void
     */
    public function test_bom_implode_endpoint_exists_and_responds(): void
    {
        // Test que el endpoint existe (incluso si no hay recetas)
        $response = $this->getJson('/api/recipes/REC-NONEXISTENT/bom/implode');
        
        // Debe responder (404 es aceptable si no existe la receta)
        $this->assertTrue(
            $response->status() === 200 || $response->status() === 404,
            'Endpoint debe responder 200 o 404, obtuvo: ' . $response->status()
        );
        
        // Debe tener formato JSON correcto
        $response->assertJsonStructure([
            'ok',
            'recipe_id',
        ]);
    }

    /**
     * Test de validación del response format
     * 
     * @return void
     */
    public function test_bom_implode_response_format_is_correct(): void
    {
        $response = $this->getJson('/api/recipes/REC-TEST/bom/implode');
        
        // Independientemente del status, debe tener ok y recipe_id
        $data = $response->json();
        
        $this->assertArrayHasKey('ok', $data);
        $this->assertArrayHasKey('recipe_id', $data);
        $this->assertIsBool($data['ok']);
        
        if ($data['ok'] === true) {
            // Si fue exitoso, debe tener estos campos
            $this->assertArrayHasKey('recipe_name', $data);
            $this->assertArrayHasKey('base_ingredients', $data);
            $this->assertArrayHasKey('total_ingredients', $data);
            $this->assertIsArray($data['base_ingredients']);
        } else {
            // Si falló, debe tener mensaje de error
            $this->assertArrayHasKey('message', $data);
        }
    }
}
