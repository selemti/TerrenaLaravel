<?php

namespace Tests\Unit\Services;

use App\Services\Inventory\UomConversionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use InvalidArgumentException;
use Tests\TestCase;

class UomConversionServiceTest extends TestCase
{
    use RefreshDatabase;

    protected UomConversionService $uomConversionService;

    protected function setUp(): void
    {
        parent::setUp();

        $this->uomConversionService = new UomConversionService();
    }

    public function test_convert_successfully(): void
    {
        $result = $this->uomConversionService->convert(1, 'KG', 'G', 1);

        $this->assertIsFloat($result);
        $this->assertEquals(1000.0, $result); // 1 KG = 1000 G
    }

    public function test_convert_invalid_base_unit(): void
    {
        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('Unidad base no válida');

        $this->uomConversionService->convert(1, 'INVALID', 'G', 1);
    }

    public function test_convert_invalid_target_unit(): void
    {
        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('Unidad destino no válida');

        $this->uomConversionService->convert(1, 'KG', 'INVALID', 1);
    }

    public function test_convert_same_unit(): void
    {
        $result = $this->uomConversionService->convert(1, 'KG', 'KG', 5);

        $this->assertIsFloat($result);
        $this->assertEquals(5.0, $result); // 5 KG = 5 KG
    }

    public function test_calculate_conversion_factor_successfully(): void
    {
        $result = $this->uomConversionService->calculateConversionFactor('KG', 'G');

        $this->assertIsFloat($result);
        $this->assertEquals(1000.0, $result); // 1 KG = 1000 G
    }

    public function test_calculate_conversion_factor_invalid_units(): void
    {
        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('Unidad origen no válida');

        $this->uomConversionService->calculateConversionFactor('INVALID', 'G');
    }

    public function test_calculate_conversion_factor_same_unit(): void
    {
        $result = $this->uomConversionService->calculateConversionFactor('KG', 'KG');

        $this->assertIsFloat($result);
        $this->assertEquals(1.0, $result); // 1 KG = 1 KG
    }
    
    public function test_validate_circular_conversion(): void
    {
        // This should pass without throwing an exception
        $result = $this->uomConversionService->validateCircularConversion('KG', 'G', 1000);
        $this->assertTrue($result);
    }
    
    public function test_validate_circular_conversion_invalid(): void
    {
        $result = $this->uomConversionService->validateCircularConversion('KG', 'G', 999);
        $this->assertFalse($result);
    }
}