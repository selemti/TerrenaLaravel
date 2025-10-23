<?php

namespace Tests\Unit\Inventory;

use App\Services\Inventory\InventoryCountService;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;
use ReflectionClass;

class InventoryCountServiceTest extends TestCase
{
    public function test_normalize_line_requires_item_id(): void
    {
        $service = new InventoryCountService();

        $this->expectException(InvalidArgumentException::class);

        $this->invokeNormalizeLine($service, [
            'expected_qty' => 2,
            'counted_qty' => 1,
        ]);
    }

    public function test_normalize_line_maps_expected_fields(): void
    {
        $service = new InventoryCountService();

        $result = $this->invokeNormalizeLine($service, [
            'item_id' => 10,
            'expected_qty' => 5,
            'counted_qty' => 4.5,
            'uom' => 'KG',
            'reason' => 'MERMA',
            'notes' => 'diferencia turno',
        ]);

        $this->assertSame(10, $result['item_id']);
        $this->assertSame(5.0, $result['qty_teorica']);
        $this->assertSame(4.5, $result['qty_contada']);
        $this->assertSame(-0.5, $result['qty_variacion']);
        $this->assertSame('KG', $result['uom']);
        $this->assertSame('MERMA', $result['motivo']);
        $this->assertNotNull($result['meta']);
    }

    private function invokeNormalizeLine(InventoryCountService $service, array $payload): array
    {
        $reflection = new ReflectionClass($service);
        $method = $reflection->getMethod('normalizeLine');
        $method->setAccessible(true);

        return $method->invoke($service, $payload);
    }
}
