<?php

namespace Tests\Unit\Services;

use App\Services\Inventory\UomConversionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UomConversionServiceTest extends TestCase
{
    use RefreshDatabase;

    protected UomConversionService $uomConversionService;

    protected function setUp(): void
    {
        parent::setUp();

        $this->uomConversionService = new UomConversionService;
    }

    public function test_convert_successfully(): void
    {
        $result = $this->uomConversionService->convert(1, 'KG', 'G');

        $this->assertIsArray($result);
        $this->assertTrue($result['success']);
        $this->assertIsFloat($result['result']);
        $this->assertEquals(1000.0, $result['result']); // 1 KG = 1000 G
    }

    public function test_convert_invalid_base_unit(): void
    {
        $result = $this->uomConversionService->convert(1, 'INVALID', 'G');

        $this->assertIsArray($result);
        $this->assertFalse($result['success']);
        $this->assertNotNull($result['error']);
    }

    public function test_convert_invalid_target_unit(): void
    {
        $result = $this->uomConversionService->convert(1, 'KG', 'INVALID');

        $this->assertIsArray($result);
        $this->assertFalse($result['success']);
        $this->assertNotNull($result['error']);
    }

    public function test_convert_same_unit(): void
    {
        $result = $this->uomConversionService->convert(5, 'KG', 'KG');

        $this->assertIsArray($result);
        $this->assertTrue($result['success']);
        $this->assertEquals(5.0, $result['result']); // 5 KG = 5 KG
    }

    public function test_can_convert_known_units(): void
    {
        $this->assertTrue($this->uomConversionService->canConvert('KG', 'G'));
        $this->assertTrue($this->uomConversionService->canConvert('L', 'ML'));
        $this->assertFalse($this->uomConversionService->canConvert('KG', 'INVALID'));
    }

    public function test_can_convert_same_unit(): void
    {
        $this->assertTrue($this->uomConversionService->canConvert('KG', 'KG'));
    }

    public function test_get_conversions_for_known_uom(): void
    {
        $conversions = $this->uomConversionService->getConversionsFor('KG');

        $this->assertIsArray($conversions);
    }

    public function test_normalize_to_base_kg(): void
    {
        $result = $this->uomConversionService->normalizeToBase(500.0, 'G', 'PESO');

        $this->assertIsArray($result);
        $this->assertTrue($result['success']);
        $this->assertEquals(0.5, $result['normalized_value']); // 500 G = 0.5 KG
        $this->assertEquals('KG', $result['base_uom']);
    }
}
