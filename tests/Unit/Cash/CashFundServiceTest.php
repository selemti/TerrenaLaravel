<?php

namespace Tests\Unit\Cash;

use App\Services\Cash\CashFundService;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;

class CashFundServiceTest extends TestCase
{
    public function test_normalize_opening_requires_sucursal_and_creator(): void
    {
        $service = new CashFundService();

        $this->expectException(InvalidArgumentException::class);
        $this->invokeMethod($service, 'normalizeOpening', [[]]);
    }

    public function test_normalize_movement_requires_positive_amount(): void
    {
        $service = new CashFundService();

        $this->expectException(InvalidArgumentException::class);
        $this->invokeMethod($service, 'normalizeMovement', [[
            'monto' => 0,
        ]]);
    }

    protected function invokeMethod(object $object, string $method, array $parameters)
    {
        $reflection = new \ReflectionClass($object);
        $methodReflection = $reflection->getMethod($method);
        $methodReflection->setAccessible(true);

        return $methodReflection->invokeArgs($object, $parameters);
    }
}
