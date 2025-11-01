<?php

namespace Tests\Unit\Inventory;

use App\Services\Inventory\UomConversionService;
use Tests\TestCase;

/**
 * UomConversionServiceTest
 *
 * Unit tests for UOM conversion service
 *
 * Tests cover:
 * - Exact conversions (metric)
 * - Approximate conversions (culinary)
 * - Inverse conversions
 * - Roundtrip calculations
 * - Error handling
 * - Scope preferences
 *
 * @package Tests\Unit\Inventory
 */
class UomConversionServiceTest extends TestCase
{
    protected UomConversionService $service;

    /**
     * Setup: Create service instance
     */
    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new UomConversionService();
    }

    /**
     * Test: Convert KG to G (exact metric conversion)
     */
    public function test_convert_kg_to_g_exact()
    {
        $result = $this->service->convert(2.5, 'KG', 'G');

        $this->assertTrue($result['success'], 'Conversion should succeed');
        $this->assertEquals(2500.0, $result['result'], 'Result should be 2500 G');
        $this->assertFalse($result['is_approx'], 'Conversion should be exact');
        $this->assertEquals(1000.0, $result['factor'], 'Factor should be 1000');
        $this->assertEquals('global', $result['scope'], 'Scope should be global');
        $this->assertNull($result['error'], 'No error should be present');
    }

    /**
     * Test: Convert G to KG (inverse, exact)
     */
    public function test_convert_g_to_kg_exact()
    {
        $result = $this->service->convert(5000, 'G', 'KG');

        $this->assertTrue($result['success'], 'Conversion should succeed');
        $this->assertEquals(5.0, $result['result'], 'Result should be 5 KG');
        $this->assertFalse($result['is_approx'], 'Conversion should be exact');
        $this->assertEquals(0.001, $result['factor'], 'Factor should be 0.001');
        $this->assertEquals('global', $result['scope'], 'Scope should be global');
    }

    /**
     * Test: Convert L to ML (exact metric conversion)
     */
    public function test_convert_l_to_ml_exact()
    {
        $result = $this->service->convert(1.5, 'L', 'ML');

        $this->assertTrue($result['success'], 'Conversion should succeed');
        $this->assertEquals(1500.0, $result['result'], 'Result should be 1500 ML');
        $this->assertFalse($result['is_approx'], 'Conversion should be exact');
        $this->assertEquals('global', $result['scope'], 'Scope should be global');
    }

    /**
     * Test: Convert LB to G (exact imperial to metric)
     */
    public function test_convert_lb_to_g_exact()
    {
        $result = $this->service->convert(1.0, 'LB', 'G');

        $this->assertTrue($result['success'], 'Conversion should succeed');
        $this->assertEqualsWithDelta(453.59237, $result['result'], 0.001, 'Result should be ~453.59 G');
        $this->assertFalse($result['is_approx'], 'Conversion should be exact');
        $this->assertEquals('global', $result['scope'], 'Scope should be global');
    }

    /**
     * Test: Convert CUP to ML (approximate culinary)
     */
    public function test_convert_cup_to_ml_approximate()
    {
        $result = $this->service->convert(1.0, 'CUP', 'ML');

        $this->assertTrue($result['success'], 'Conversion should succeed');
        $this->assertEqualsWithDelta(240.0, $result['result'], 1.0, 'Result should be ~240 ML');
        $this->assertTrue($result['is_approx'], 'Conversion should be approximate');
        $this->assertEquals('house', $result['scope'], 'Scope should be house');
        $this->assertNotNull($result['notes'], 'Notes should be present');
    }

    /**
     * Test: Convert ML to CUP (approximate culinary inverse)
     */
    public function test_convert_ml_to_cup_approximate()
    {
        $result = $this->service->convert(240.0, 'ML', 'CUP');

        $this->assertTrue($result['success'], 'Conversion should succeed');
        $this->assertEqualsWithDelta(1.0, $result['result'], 0.01, 'Result should be ~1 CUP');
        $this->assertTrue($result['is_approx'], 'Conversion should be approximate');
        $this->assertEquals('house', $result['scope'], 'Scope should be house');
    }

    /**
     * Test: Same UOM (no conversion needed)
     */
    public function test_convert_same_uom()
    {
        $result = $this->service->convert(10.5, 'KG', 'KG');

        $this->assertTrue($result['success'], 'Conversion should succeed');
        $this->assertEquals(10.5, $result['result'], 'Result should be unchanged');
        $this->assertFalse($result['is_approx'], 'Should not be approximate');
        $this->assertEquals(1.0, $result['factor'], 'Factor should be 1.0');
        $this->assertStringContainsString('No conversion needed', $result['notes']);
    }

    /**
     * Test: Non-existent UOM (should fail)
     */
    public function test_convert_nonexistent_uom_fails()
    {
        $result = $this->service->convert(10, 'INVALID', 'KG');

        $this->assertFalse($result['success'], 'Conversion should fail');
        $this->assertNull($result['result'], 'Result should be null');
        $this->assertNotNull($result['error'], 'Error message should be present');
        $this->assertStringContainsString('No conversion found', $result['error']);
    }

    /**
     * Test: No conversion path exists (should fail)
     */
    public function test_convert_no_path_fails()
    {
        // Try to convert between incompatible units (if they exist without a conversion)
        // This test assumes there's no direct conversion from HR to PZ
        $result = $this->service->convert(1.0, 'HR', 'PZ');

        $this->assertFalse($result['success'], 'Conversion should fail');
        $this->assertNotNull($result['error'], 'Error message should be present');
    }

    /**
     * Test: Roundtrip KG → G → KG
     */
    public function test_roundtrip_kg_g_kg()
    {
        $original = 5.75;

        // KG → G
        $step1 = $this->service->convert($original, 'KG', 'G');
        $this->assertTrue($step1['success']);

        // G → KG
        $step2 = $this->service->convert($step1['result'], 'G', 'KG');
        $this->assertTrue($step2['success']);

        // Should return to original value
        $this->assertEqualsWithDelta($original, $step2['result'], 0.0001, 'Roundtrip should return original value');
    }

    /**
     * Test: Roundtrip L → ML → L
     */
    public function test_roundtrip_l_ml_l()
    {
        $original = 3.25;

        $step1 = $this->service->convert($original, 'L', 'ML');
        $this->assertTrue($step1['success']);

        $step2 = $this->service->convert($step1['result'], 'ML', 'L');
        $this->assertTrue($step2['success']);

        $this->assertEqualsWithDelta($original, $step2['result'], 0.0001, 'Roundtrip should return original value');
    }

    /**
     * Test: Roundtrip CUP → ML → CUP (approximate)
     */
    public function test_roundtrip_cup_ml_cup()
    {
        $original = 2.0;

        $step1 = $this->service->convert($original, 'CUP', 'ML');
        $this->assertTrue($step1['success']);

        $step2 = $this->service->convert($step1['result'], 'ML', 'CUP');
        $this->assertTrue($step2['success']);

        // Allow larger delta for approximate conversions
        $this->assertEqualsWithDelta($original, $step2['result'], 0.01, 'Roundtrip should return ~original value');
    }

    /**
     * Test: canConvert method
     */
    public function test_can_convert()
    {
        $this->assertTrue($this->service->canConvert('KG', 'G'), 'Should be able to convert KG to G');
        $this->assertTrue($this->service->canConvert('L', 'ML'), 'Should be able to convert L to ML');
        $this->assertTrue($this->service->canConvert('KG', 'KG'), 'Same UOM should be convertible');
        $this->assertFalse($this->service->canConvert('INVALID', 'KG'), 'Invalid UOM should not be convertible');
    }

    /**
     * Test: getConversionsFor method
     */
    public function test_get_conversions_for()
    {
        $conversions = $this->service->getConversionsFor('KG', 'from');

        $this->assertIsArray($conversions, 'Should return array');
        $this->assertNotEmpty($conversions, 'KG should have conversions');

        // Check structure of first conversion
        if (count($conversions) > 0) {
            $first = $conversions[0];
            $this->assertArrayHasKey('from', $first);
            $this->assertArrayHasKey('to', $first);
            $this->assertArrayHasKey('factor', $first);
            $this->assertArrayHasKey('is_exact', $first);
            $this->assertArrayHasKey('scope', $first);
            $this->assertEquals('KG', $first['from']);
        }
    }

    /**
     * Test: normalizeToBase for PESO (mass)
     */
    public function test_normalize_to_base_peso()
    {
        $result = $this->service->normalizeToBase(500, 'G', 'PESO');

        $this->assertTrue($result['success'], 'Normalization should succeed');
        $this->assertEquals(0.5, $result['normalized_value'], 'Should normalize to 0.5 KG');
        $this->assertEquals('KG', $result['base_uom'], 'Base UOM should be KG');
        $this->assertEquals('G', $result['original_uom'], 'Original UOM should be G');
        $this->assertFalse($result['is_approx'], 'Should be exact');
    }

    /**
     * Test: normalizeToBase for VOLUMEN (volume)
     */
    public function test_normalize_to_base_volumen()
    {
        $result = $this->service->normalizeToBase(2500, 'ML', 'VOLUMEN');

        $this->assertTrue($result['success'], 'Normalization should succeed');
        $this->assertEquals(2.5, $result['normalized_value'], 'Should normalize to 2.5 L');
        $this->assertEquals('L', $result['base_uom'], 'Base UOM should be L');
        $this->assertEquals('ML', $result['original_uom'], 'Original UOM should be ML');
    }

    /**
     * Test: normalizeToBase for UNIDAD (unit/piece)
     */
    public function test_normalize_to_base_unidad()
    {
        $result = $this->service->normalizeToBase(10, 'PZ', 'UNIDAD');

        $this->assertTrue($result['success'], 'Normalization should succeed');
        $this->assertEquals(10, $result['normalized_value'], 'Should remain 10 PZ');
        $this->assertEquals('PZ', $result['base_uom'], 'Base UOM should be PZ');
    }

    /**
     * Test: Prefer global scope over house
     */
    public function test_prefer_global_scope()
    {
        // If there are duplicate conversions with different scopes,
        // the service should prefer 'global' when preferScope = 'any'
        $result = $this->service->convert(1.0, 'KG', 'G', 'any');

        $this->assertTrue($result['success']);
        $this->assertEquals('global', $result['scope'], 'Should prefer global scope');
    }

    /**
     * Test: Case insensitivity of UOM claves
     */
    public function test_case_insensitivity()
    {
        $result1 = $this->service->convert(1.0, 'kg', 'g');
        $result2 = $this->service->convert(1.0, 'KG', 'G');

        $this->assertTrue($result1['success']);
        $this->assertTrue($result2['success']);
        $this->assertEquals($result1['result'], $result2['result'], 'Lowercase and uppercase should give same result');
    }
}
