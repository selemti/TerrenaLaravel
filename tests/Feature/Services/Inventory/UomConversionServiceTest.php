<?php

namespace Tests\Feature\Services\Inventory;

use Tests\TestCase;

/**
 * These tests were written for a legacy UomConversionService API (ID-based conversions).
 * The current service uses clave-based conversions (KG, G, L, etc.).
 * See tests/Unit/Services/UomConversionServiceTest.php for the current API tests.
 */
class UomConversionServiceTest extends TestCase
{
    public function test_legacy_tests_skipped(): void
    {
        $this->markTestSkipped('Legacy UomConversionService tests — written for ID-based API. Current API is clave-based. See Unit tests.');
    }
}
