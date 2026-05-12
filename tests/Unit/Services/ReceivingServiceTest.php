<?php

namespace Tests\Unit\Services;

use App\Services\Inventory\ReceivingService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Exceptions\Inventory\InventoryValidationException;
use Tests\TestCase;

class ReceivingServiceTest extends TestCase
{
    use RefreshDatabase;

    protected ReceivingService $receivingService;

    protected function setUp(): void
    {
        parent::setUp();

        $this->receivingService = new ReceivingService;
    }

    public function test_guard_positive_id_throws_exception_for_invalid_id(): void
    {
        $reflection = new \ReflectionClass(ReceivingService::class);
        $method = $reflection->getMethod('guardPositiveId');
        $method->setAccessible(true);

        $service = new ReceivingService;

        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('The test id must be greater than zero.');

        $method->invoke($service, 0, 'test');
    }

    public function test_create_draft_reception_successfully(): void
    {
        $result = $this->receivingService->createDraftReception(1, 1);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('recepcion_id', $result);
        $this->assertArrayHasKey('status', $result);
        $this->assertEquals('EN_PROCESO', $result['status']);
    }

    public function test_create_draft_reception_throws_exception_for_invalid_ids(): void
    {
        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('The purchase order id must be greater than zero.');

        $this->receivingService->createDraftReception(0, 1);
    }

    public function test_update_reception_lines_successfully(): void
    {
        $lineItems = [
            [
                'item_id' => 1,
                'qty' => 10,
                'costo' => 100,
                'uom' => 'PZ',
            ],
        ];

        $result = $this->receivingService->updateReceptionLines(1, $lineItems, 1);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('recepcion_id', $result);
        $this->assertArrayHasKey('lines_processed', $result);
        $this->assertEquals(1, $result['lines_processed']);
    }

    public function test_update_reception_lines_throws_exception_for_invalid_ids(): void
    {
        $lineItems = [
            [
                'item_id' => 1,
                'qty' => 10,
                'costo' => 100,
                'uom' => 'PZ',
            ],
        ];

        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('The recepcion id must be greater than zero.');

        $this->receivingService->updateReceptionLines(0, $lineItems, 1);
    }

    public function test_update_reception_lines_throws_exception_for_empty_line_items(): void
    {
        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('Line items array cannot be empty.');

        $this->receivingService->updateReceptionLines(1, [], 1);
    }

    public function test_validate_reception_successfully(): void
    {
        $result = $this->receivingService->validateReception(1, 1);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('recepcion_id', $result);
        $this->assertArrayHasKey('status', $result);
        $this->assertArrayHasKey('requiere_aprobacion', $result);
        $this->assertEquals('VALIDADA', $result['status']);
        $this->assertFalse($result['requiere_aprobacion']);
    }

    public function test_validate_reception_throws_exception_for_invalid_ids(): void
    {
        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('The recepcion id must be greater than zero.');

        $this->receivingService->validateReception(0, 1);
    }

    public function test_approve_reception_successfully(): void
    {
        $result = $this->receivingService->approveReception(1, 1);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('recepcion_id', $result);
        $this->assertArrayHasKey('status', $result);
        $this->assertArrayHasKey('requiere_aprobacion', $result);
        $this->assertEquals('VALIDADA', $result['status']);
        $this->assertFalse($result['requiere_aprobacion']);
    }

    public function test_approve_reception_throws_exception_for_invalid_ids(): void
    {
        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('The recepcion id must be greater than zero.');

        $this->receivingService->approveReception(0, 1);
    }

    public function test_get_reception_successfully(): void
    {
        $result = $this->receivingService->getReception(1);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('recepcion_id', $result);
        $this->assertArrayHasKey('estado', $result);
        $this->assertArrayHasKey('requiere_aprobacion', $result);
        $this->assertArrayHasKey('lineas', $result);
        $this->assertEquals(1, $result['recepcion_id']);
    }

    public function test_get_reception_throws_exception_for_invalid_ids(): void
    {
        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('The recepcion id must be greater than zero.');

        $this->receivingService->getReception(0);
    }

    public function test_post_to_inventory_successfully(): void
    {
        $result = $this->receivingService->postToInventory(1, 1);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('recepcion_id', $result);
        $this->assertArrayHasKey('movimientos_generados', $result);
        $this->assertArrayHasKey('status', $result);
        $this->assertEquals('CERRADA', $result['status']);
    }

    public function test_post_to_inventory_throws_exception_for_invalid_ids(): void
    {
        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('The recepcion id must be greater than zero.');

        $this->receivingService->postToInventory(0, 1);
    }

    public function test_finalize_costing_successfully(): void
    {
        $result = $this->receivingService->finalizeCosting(1, 1);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('recepcion_id', $result);
        $this->assertArrayHasKey('total_valorizado', $result);
        $this->assertArrayHasKey('status', $result);
        $this->assertEquals('COSTO_FINAL_APLICADO', $result['status']);
    }

    public function test_finalize_costing_throws_exception_for_invalid_ids(): void
    {
        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('The recepcion id must be greater than zero.');

        $this->receivingService->finalizeCosting(0, 1);
    }
}
