<?php

namespace Tests\Feature\Services\Inventory;

use App\Services\Inventory\UomConversionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class UomConversionServiceTest extends TestCase
{
    use RefreshDatabase;

    protected UomConversionService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $this->service = app(UomConversionService::class);

        // Crear unidades de medida de prueba
        $this->createTestUoms();
    }

    private function createTestUoms(): void
    {
        // Unidad base: kilogramo (KG)
        DB::connection('pgsql')->table('selemti.unidades_medida')->insert([
            'id' => 1,
            'codigo' => 'KG',
            'nombre' => 'Kilogramo',
            'descripcion' => 'Kilogramo',
            'tipo' => 'peso',
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Unidad derivada: gramo (G)
        DB::connection('pgsql')->table('selemti.unidades_medida')->insert([
            'id' => 2,
            'codigo' => 'G',
            'nombre' => 'Gramo',
            'descripcion' => 'Gramo',
            'tipo' => 'peso',
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Unidad derivada: tonelada (TON)
        DB::connection('pgsql')->table('selemti.unidades_medida')->insert([
            'id' => 3,
            'codigo' => 'TON',
            'nombre' => 'Tonelada',
            'descripcion' => 'Tonelada',
            'tipo' => 'peso',
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Crear conversiones
        DB::connection('pgsql')->table('selemti.unidades_conversiones')->insert([
            'unidad_origen_id' => 2, // G
            'unidad_destino_id' => 1, // KG
            'factor' => 0.001,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.unidades_conversiones')->insert([
            'unidad_origen_id' => 1, // KG
            'unidad_destino_id' => 2, // G
            'factor' => 1000,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.unidades_conversiones')->insert([
            'unidad_origen_id' => 3, // TON
            'unidad_destino_id' => 1, // KG
            'factor' => 1000,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    /** @test */
    public function test_can_convert_units_in_same_category()
    {
        // Convertir 5000 gramos a kilogramos
        $result = $this->service->convert(5000, 2, 1); // 5000 G to KG

        $this->assertEquals(5.0, $result);

        // Convertir 3 kilogramos a gramos
        $result = $this->service->convert(3, 1, 2); // 3 KG to G

        $this->assertEquals(3000.0, $result);

        // Convertir 2 toneladas a kilogramos
        $result = $this->service->convert(2, 3, 1); // 2 TON to KG

        $this->assertEquals(2000.0, $result);
    }

    /** @test */
    public function test_convert_direct_route()
    {
        $result = $this->service->convert(1500, 2, 1, true); // 1500 G to KG, direct only
        $this->assertEquals(1.5, $result);
    }

    /** @test */
    public function test_convert_via_base_unit()
    {
        // Suponiendo que hay una conversión a través de una unidad base
        // Convertir 1 tonelada a gramos (TON -> KG -> G)
        $result = $this->service->convert(1, 3, 2); // 1 TON to G
        $this->assertEquals(1000000.0, $result);
    }

    /** @test */
    public function test_get_conversion_factor()
    {
        $factor = $this->service->getConversionFactor(2, 1); // G to KG
        $this->assertEquals(0.001, $factor);

        $factor = $this->service->getConversionFactor(1, 2); // KG to G
        $this->assertEquals(1000, $factor);
    }

    /** @test */
    public function test_get_available_conversions()
    {
        $conversions = $this->service->getAvailableConversions(1); // From KG

        $this->assertIsArray($conversions);
        $this->assertContains(2, $conversions); // Should be able to convert to G
        $this->assertContains(3, $conversions); // Should be able to convert to TON
    }

    /** @test */
    public function test_get_conversion_path()
    {
        // Get path from TON to G (should go TON->KG->G)
        $path = $this->service->getConversionPath(3, 2); // TON to G

        $this->assertIsArray($path);
        $this->assertGreaterThanOrEqual(2, count($path)); // At least 2 steps
    }

    /** @test */
    public function test_convert_with_nonexistent_units()
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Invalid origin unit id: 999');

        $result = $this->service->convert(100, 999, 1);
    }

    /** @test */
    public function test_convert_without_path()
    {
        // Crear una unidad sin conversiones
        DB::connection('pgsql')->table('selemti.unidades_medida')->insert([
            'id' => 4,
            'codigo' => 'L',
            'nombre' => 'Litro',
            'descripcion' => 'Litro',
            'tipo' => 'volumen',
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('No conversion path available from L to G');

        $result = $this->service->convert(10, 4, 2); // L to G should fail
    }

    /** @test */
    public function test_get_uom_info()
    {
        $info = $this->service->getUomInfo(1);
        $this->assertIsArray($info);
        $this->assertEquals('KG', $info['codigo']);
        $this->assertEquals('Kilogramo', $info['nombre']);

        $info = $this->service->getUomInfo(2);
        $this->assertIsArray($info);
        $this->assertEquals('G', $info['codigo']);
    }
}
