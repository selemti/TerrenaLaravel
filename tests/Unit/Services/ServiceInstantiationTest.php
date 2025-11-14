<?php

namespace Tests\Unit\Services;

use App\Services\Inventory\ReceivingService;
use App\Services\Inventory\TransferService;
use App\Services\Inventory\UomConversionService;
use Tests\TestCase;

class ServiceInstantiationTest extends TestCase
{
    public function test_transfer_service_can_be_instantiated(): void
    {
        $service = new TransferService;
        $this->assertInstanceOf(TransferService::class, $service);
    }

    public function test_receiving_service_can_be_instantiated(): void
    {
        $service = new ReceivingService;
        $this->assertInstanceOf(ReceivingService::class, $service);
    }

    public function test_uom_conversion_service_can_be_instantiated(): void
    {
        $service = new UomConversionService;
        $this->assertInstanceOf(UomConversionService::class, $service);
    }
}
