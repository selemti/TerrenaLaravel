<?php

namespace Tests\Feature;

use App\Models\Catalogs\Almacen;
use App\Models\Catalogs\Sucursal;
use App\Models\Catalogs\Unidad;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CatalogsApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
    }

    /** @test */
    public function test_can_get_categories()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/categories');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data' => [
                    '*' => ['id', 'name', 'visible']
                ],
                'timestamp'
            ])
            ->assertJsonPath('ok', true);
    }

    /** @test */
    public function test_can_filter_visible_categories_only()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/categories');

        $response->assertStatus(200);
        
        $categories = $response->json('data');
        if (count($categories) > 0) {
            foreach ($categories as $category) {
                $this->assertTrue($category['visible'] ?? true);
            }
        }
    }

    /** @test */
    public function test_can_get_all_categories_including_hidden()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/categories?show_all=true');

        $response->assertStatus(200)
            ->assertJsonPath('ok', true);
    }

    /** @test */
    public function test_can_get_almacenes()
    {
        Almacen::factory()->create([
            'nombre' => 'Almacén Test',
            'clave' => 'ALM-TEST',
            'activo' => true,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/almacenes');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data' => [
                    '*' => ['id', 'nombre', 'clave', 'activo']
                ],
                'timestamp'
            ])
            ->assertJsonPath('ok', true);

        $almacenes = $response->json('data');
        $this->assertGreaterThan(0, count($almacenes));
    }

    /** @test */
    public function test_can_filter_almacenes_by_sucursal()
    {
        $sucursal = Sucursal::factory()->create();
        
        Almacen::factory()->create([
            'sucursal_id' => $sucursal->id,
            'nombre' => 'Almacén Sucursal 1',
            'activo' => true,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/catalogs/almacenes?sucursal_id={$sucursal->id}");

        $response->assertStatus(200)
            ->assertJsonPath('ok', true);

        $almacenes = $response->json('data');
        foreach ($almacenes as $almacen) {
            $this->assertEquals($sucursal->id, $almacen['sucursal_id']);
        }
    }

    /** @test */
    public function test_only_shows_active_almacenes_by_default()
    {
        Almacen::factory()->create(['activo' => true]);
        Almacen::factory()->create(['activo' => false]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/almacenes');

        $response->assertStatus(200);
        
        $almacenes = $response->json('data');
        foreach ($almacenes as $almacen) {
            $this->assertTrue($almacen['activo']);
        }
    }

    /** @test */
    public function test_can_get_sucursales()
    {
        Sucursal::factory()->count(3)->create(['activo' => true]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/sucursales');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data' => [
                    '*' => ['id', 'nombre', 'activo']
                ],
                'timestamp'
            ])
            ->assertJsonPath('ok', true);

        $sucursales = $response->json('data');
        $this->assertGreaterThanOrEqual(3, count($sucursales));
    }

    /** @test */
    public function test_only_shows_active_sucursales_by_default()
    {
        Sucursal::factory()->create(['activo' => true]);
        Sucursal::factory()->create(['activo' => false]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/sucursales');

        $response->assertStatus(200);
        
        $sucursales = $response->json('data');
        foreach ($sucursales as $sucursal) {
            $this->assertTrue($sucursal['activo']);
        }
    }

    /** @test */
    public function test_can_get_movement_types()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/movement-types');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data' => [
                    '*' => ['value', 'label', 'description', 'affects_stock', 'sign']
                ],
                'timestamp'
            ])
            ->assertJsonPath('ok', true);

        $types = $response->json('data');
        
        // Verificar que existen los tipos principales
        $values = array_column($types, 'value');
        $this->assertContains('ENTRADA', $values);
        $this->assertContains('SALIDA', $values);
        $this->assertContains('TRASPASO_IN', $values);
        $this->assertContains('TRASPASO_OUT', $values);
        $this->assertContains('RECEPCION', $values);
    }

    /** @test */
    public function test_movement_types_have_correct_signs()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/movement-types');

        $response->assertStatus(200);

        $types = collect($response->json('data'));
        
        // Entradas deben tener signo +
        $entrada = $types->firstWhere('value', 'ENTRADA');
        $this->assertEquals('+', $entrada['sign']);

        // Salidas deben tener signo -
        $salida = $types->firstWhere('value', 'SALIDA');
        $this->assertEquals('-', $salida['sign']);

        // Traspasos
        $traspasoIn = $types->firstWhere('value', 'TRASPASO_IN');
        $this->assertEquals('+', $traspasoIn['sign']);

        $traspasoOut = $types->firstWhere('value', 'TRASPASO_OUT');
        $this->assertEquals('-', $traspasoOut['sign']);
    }

    /** @test */
    public function test_can_get_unidades()
    {
        Unidad::factory()->count(5)->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/unidades');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'count',
                'data' => [
                    '*' => ['id', 'codigo', 'nombre', 'tipo']
                ],
                'timestamp'
            ])
            ->assertJsonPath('ok', true);
    }

    /** @test */
    public function test_can_filter_unidades_by_tipo()
    {
        Unidad::factory()->create(['tipo' => 'PESO']);
        Unidad::factory()->create(['tipo' => 'VOLUMEN']);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/unidades?tipo=PESO');

        $response->assertStatus(200);

        $unidades = $response->json('data');
        foreach ($unidades as $unidad) {
            $this->assertEquals('PESO', $unidad['tipo']);
        }
    }

    /** @test */
    public function test_can_get_unidades_count_only()
    {
        Unidad::factory()->count(10)->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/unidades?only_count=true');

        $response->assertStatus(200)
            ->assertJsonPath('ok', true)
            ->assertJsonStructure(['ok', 'count', 'data', 'timestamp']);

        $this->assertGreaterThanOrEqual(10, $response->json('count'));
        $this->assertEmpty($response->json('data'));
    }

    /** @test */
    public function test_unidades_respects_limit_parameter()
    {
        Unidad::factory()->count(20)->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/catalogs/unidades?limit=5');

        $response->assertStatus(200);

        $unidades = $response->json('data');
        $this->assertLessThanOrEqual(5, count($unidades));
    }

    /** @test */
    public function test_all_catalog_endpoints_require_authentication()
    {
        $endpoints = [
            '/api/catalogs/categories',
            '/api/catalogs/almacenes',
            '/api/catalogs/sucursales',
            '/api/catalogs/movement-types',
            '/api/catalogs/unidades',
        ];

        foreach ($endpoints as $endpoint) {
            $response = $this->getJson($endpoint);
            $response->assertStatus(401); // Unauthorized
        }
    }

    /** @test */
    public function test_catalogs_return_consistent_response_structure()
    {
        $endpoints = [
            '/api/catalogs/categories',
            '/api/catalogs/almacenes',
            '/api/catalogs/sucursales',
            '/api/catalogs/movement-types',
            '/api/catalogs/unidades',
        ];

        foreach ($endpoints as $endpoint) {
            $response = $this->actingAs($this->user, 'sanctum')
                ->getJson($endpoint);

            $response->assertStatus(200)
                ->assertJsonStructure(['ok', 'data', 'timestamp'])
                ->assertJsonPath('ok', true);
        }
    }
}
