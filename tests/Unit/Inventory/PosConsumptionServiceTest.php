<?php

namespace Tests\Unit\Inventory;

use App\Services\Inventory\PosConsumptionService;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;

class PosConsumptionServiceTest extends TestCase
{
    public function test_normalize_line_success(): void
    {
        $service = new PosConsumptionService();

        $normalized = $service->normalizeLine([
            'item_id' => 5,
            'uom' => 'KG',
            'cantidad' => 2.5,
            'factor' => 1.2,
            'origen' => 'RECETA',
            'meta' => ['ticket_item_id' => 11],
        ]);

        $this->assertSame(5, $normalized['item_id']);
        $this->assertSame('KG', $normalized['uom']);
        $this->assertSame(2.5, $normalized['cantidad']);
        $this->assertSame(1.2, $normalized['factor']);
        $this->assertSame('RECETA', $normalized['origen']);
        $this->assertSame(['ticket_item_id' => 11], $normalized['meta']);
    }

    public function test_normalize_line_rejects_zero_quantity(): void
    {
        $this->expectException(InvalidArgumentException::class);

        $service = new PosConsumptionService();
        $service->normalizeLine([
            'item_id' => 10,
            'cantidad' => 0,
        ]);
    }
}
