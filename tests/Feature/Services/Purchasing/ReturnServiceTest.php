<?php

namespace Tests\Feature\Services\Purchasing;

use App\Exceptions\Purchasing\InvalidPurchasingStateException;
use App\Services\Purchasing\ReturnService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReturnServiceTest extends TestCase
{
    use RefreshDatabase;

    protected ReturnService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $this->service = app(ReturnService::class);
    }

    public function test_create_draft_return_returns_borrador_status(): void
    {
        $result = $this->service->createDraftReturn(10, 20);

        $this->assertSame([
            'return_id' => null,
            'status' => 'BORRADOR',
        ], $result);
    }

    public function test_approve_return_returns_aprobada_status(): void
    {
        $result = $this->service->approveReturn(10, 20);

        $this->assertSame([
            'return_id' => 10,
            'status' => 'APROBADA',
        ], $result);
    }

    public function test_mark_shipped_returns_en_transito_status(): void
    {
        $result = $this->service->markShipped(10, ['guia' => 'DEV-1'], 20);

        $this->assertSame([
            'return_id' => 10,
            'status' => 'EN_TRANSITO',
        ], $result);
    }

    public function test_confirm_vendor_received_returns_received_status(): void
    {
        $result = $this->service->confirmVendorReceived(10, 20);

        $this->assertSame([
            'return_id' => 10,
            'status' => 'RECIBIDA_PROVEEDOR',
        ], $result);
    }

    public function test_post_inventory_adjustment_returns_credit_note_status(): void
    {
        $result = $this->service->postInventoryAdjustment(10, 20);

        $this->assertSame([
            'return_id' => 10,
            'movimientos_generados' => 0,
            'status' => 'NOTA_CREDITO',
        ], $result);
    }

    public function test_attach_credit_note_returns_closed_status(): void
    {
        $result = $this->service->attachCreditNote(10, ['folio' => 'NC-1'], 20);

        $this->assertSame([
            'return_id' => 10,
            'status' => 'CERRADA',
        ], $result);
    }

    public function test_public_methods_reject_invalid_ids(): void
    {
        $this->expectException(InvalidPurchasingStateException::class);
        $this->expectExceptionMessage('The return id must be greater than zero.');

        $this->service->approveReturn(0, 20);
    }
}
