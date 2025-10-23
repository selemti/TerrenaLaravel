<?php

namespace Tests\Unit\Inventory;

use App\Services\Inventory\ProductionService;
use Illuminate\Support\Carbon;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;
use ReflectionClass;

class ProductionServiceTest extends TestCase
{
    public function test_normalize_input_requires_item(): void
    {
        $service = new ProductionService();

        $this->expectException(InvalidArgumentException::class);
        $this->invokeNormalizeInput($service, ['qty' => 1, 'uom' => 'KG']);
    }

    public function test_normalize_input_maps_fields(): void
    {
        $service = new ProductionService();

        $result = $this->invokeNormalizeInput($service, [
            'item_id' => 10,
            'qty'     => 2.5,
            'uom'     => 'KG',
            'meta'    => ['source' => 'receta'],
        ]);

        $this->assertSame(10, $result['item_id']);
        $this->assertSame(2.5, $result['qty']);
        $this->assertSame('KG', $result['uom']);
        $this->assertNotNull($result['meta']);
    }

    public function test_normalize_output_requires_positive_quantity(): void
    {
        $service = new ProductionService();

        $this->expectException(InvalidArgumentException::class);
        $this->invokeNormalizeOutput($service, ['item_id' => 1, 'uom' => 'PZA', 'qty' => 0], []);
    }

    public function test_normalize_waste_requires_uom(): void
    {
        $service = new ProductionService();

        $this->expectException(InvalidArgumentException::class);
        $this->invokeNormalizeWaste($service, ['item_id' => 1, 'qty' => 1], []);
    }

    private function invokeNormalizeInput(ProductionService $service, array $payload): array
    {
        $method = (new ReflectionClass($service))->getMethod('normalizeInput');
        $method->setAccessible(true);

        return $method->invoke($service, $payload);
    }

    private function invokeNormalizeOutput(ProductionService $service, array $payload, array $header): array
    {
        $method = (new ReflectionClass($service))->getMethod('normalizeOutput');
        $method->setAccessible(true);

        return $method->invoke($service, $payload, $header, Carbon::now());
    }

    private function invokeNormalizeWaste(ProductionService $service, array $payload, array $header): array
    {
        $method = (new ReflectionClass($service))->getMethod('normalizeWaste');
        $method->setAccessible(true);

        return $method->invoke($service, $payload, $header, Carbon::now());
    }
}
