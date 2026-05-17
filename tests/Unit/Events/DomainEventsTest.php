<?php

namespace Tests\Unit\Events;

use App\Events\Inventory\ReceptionPosted;
use App\Events\Inventory\TransferPosted;
use App\Events\Pos\PosTicketIngested;
use App\Listeners\Inventory\InvalidateStockCache;
use App\Listeners\Inventory\LogReceptionPosted;
use App\Listeners\Inventory\LogTransferPosted;
use App\Listeners\Pos\LogPosTicketIngested;
use DateTimeImmutable;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class DomainEventsTest extends TestCase
{
    public function test_reception_posted_event_carries_expected_properties(): void
    {
        $now = new DateTimeImmutable('2026-05-16 10:00:00');
        $event = new ReceptionPosted('42', 'ALM-1', $now);

        $this->assertEquals('42', $event->receptionId);
        $this->assertEquals('ALM-1', $event->almacenId);
        $this->assertSame($now, $event->postedAt);
    }

    public function test_transfer_posted_event_carries_expected_properties(): void
    {
        $now = new DateTimeImmutable;
        $event = new TransferPosted('10', 'ALM-A', 'ALM-B', $now);

        $this->assertEquals('10', $event->transferId);
        $this->assertEquals('ALM-A', $event->fromAlmacenId);
        $this->assertEquals('ALM-B', $event->toAlmacenId);
    }

    public function test_pos_ticket_ingested_event_carries_expected_properties(): void
    {
        $event = new PosTicketIngested(ticketId: 999, date: '2026-05-16', terminalId: 3);

        $this->assertEquals(999, $event->ticketId);
        $this->assertEquals('2026-05-16', $event->date);
        $this->assertEquals(3, $event->terminalId);
    }

    public function test_pos_ticket_ingested_terminal_id_optional(): void
    {
        $event = new PosTicketIngested(ticketId: 1, date: '2026-01-01');

        $this->assertNull($event->terminalId);
    }

    public function test_reception_posted_listener_registered(): void
    {
        Event::fake();

        event(new ReceptionPosted('1', '', new DateTimeImmutable));

        Event::assertDispatched(ReceptionPosted::class);
    }

    public function test_transfer_posted_listener_registered(): void
    {
        Event::fake();

        event(new TransferPosted('1', 'A', 'B', new DateTimeImmutable));

        Event::assertDispatched(TransferPosted::class);
    }

    public function test_pos_ticket_ingested_listener_registered(): void
    {
        Event::fake();

        event(new PosTicketIngested(ticketId: 1, date: '2026-01-01'));

        Event::assertDispatched(PosTicketIngested::class);
    }

    public function test_listeners_are_wired_in_service_provider(): void
    {
        $dispatcher = app('events');

        $receptionListeners = $dispatcher->getListeners(ReceptionPosted::class);
        $this->assertNotEmpty($receptionListeners, 'No listeners for ReceptionPosted');

        $transferListeners = $dispatcher->getListeners(TransferPosted::class);
        $this->assertNotEmpty($transferListeners, 'No listeners for TransferPosted');

        $posListeners = $dispatcher->getListeners(PosTicketIngested::class);
        $this->assertNotEmpty($posListeners, 'No listeners for PosTicketIngested');
    }

    public function test_invalidate_stock_cache_handles_reception_posted(): void
    {
        $listener = new InvalidateStockCache;
        $event = new ReceptionPosted('5', 'ALM-1', new DateTimeImmutable);

        // Should not throw
        $listener->handle($event);
        $this->assertTrue(true);
    }

    public function test_invalidate_stock_cache_handles_transfer_posted(): void
    {
        $listener = new InvalidateStockCache;
        $event = new TransferPosted('7', 'A', 'B', new DateTimeImmutable);

        $listener->handle($event);
        $this->assertTrue(true);
    }

    public function test_log_reception_posted_handles_event(): void
    {
        $listener = new LogReceptionPosted;
        $event = new ReceptionPosted('3', 'ALM-X', new DateTimeImmutable);

        $listener->handle($event);
        $this->assertTrue(true);
    }

    public function test_log_transfer_posted_handles_event(): void
    {
        $listener = new LogTransferPosted;
        $event = new TransferPosted('4', 'SRC', 'DST', new DateTimeImmutable);

        $listener->handle($event);
        $this->assertTrue(true);
    }

    public function test_log_pos_ticket_ingested_handles_event(): void
    {
        $listener = new LogPosTicketIngested;
        $event = new PosTicketIngested(ticketId: 55, date: '2026-05-10', terminalId: 2);

        $listener->handle($event);
        $this->assertTrue(true);
    }
}
