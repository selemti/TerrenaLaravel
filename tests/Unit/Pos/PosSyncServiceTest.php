<?php

namespace Tests\Unit\Pos;

use App\Services\Inventory\PosConsumptionService;
use App\Services\Pos\PosSyncService;
use Mockery;
use Tests\TestCase;

class PosSyncServiceTest extends TestCase
{
    protected function tearDown(): void
    {
        parent::tearDown();

        Mockery::close();
    }

    public function test_ingest_tickets_returns_zero_when_empty(): void
    {
        $service = new PosSyncService(Mockery::mock(PosConsumptionService::class));

        $this->assertSame(0, $service->ingestTickets([]));
    }
}
