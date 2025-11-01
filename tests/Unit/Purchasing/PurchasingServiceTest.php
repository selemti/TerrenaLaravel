<?php

namespace Tests\Unit\Purchasing;

use App\Services\Purchasing\PurchasingService;
use Illuminate\Support\Facades\DB;
use Tests\Support\RequiresPostgresConnection;
use Tests\TestCase;

class PurchasingServiceTest extends TestCase
{
    use RequiresPostgresConnection;

    protected function setUp(): void
    {
        parent::setUp();

        $this->requirePostgresConnection();
    }

    public function test_create_request_persists_header_and_lines(): void
    {
        $service = $this->app->make(PurchasingService::class);

        $result = $service->createRequest([
            'created_by' => 1,
            'lineas' => [
                [
                    'item_id' => 10,
                    'qty' => 5,
                    'uom' => 'KG',
                    'last_price' => 120,
                ],
            ],
        ]);

        $this->assertArrayHasKey('id', $result);
        $this->assertSame('BORRADOR', $result['estado']);
        $this->assertCount(1, $result['lineas']);
        $this->assertEquals(600.0, $result['importe_estimado']);
    }

    public function test_submit_approve_and_issue_order_flow(): void
    {
        $service = $this->app->make(PurchasingService::class);

        $request = $service->createRequest([
            'created_by' => 2,
            'sucursal_id' => 'MATRIZ',
            'lineas' => [
                [
                    'item_id' => 25,
                    'qty' => 8,
                    'uom' => 'PZA',
                    'last_price' => 15,
                ],
                [
                    'item_id' => 30,
                    'qty' => 3,
                    'uom' => 'KG',
                    'last_price' => 80,
                ],
            ],
        ]);

        $lineIds = array_column($request['lineas'], 'id', 'item_id');

        $quote = $service->submitQuote($request['id'], [
            'vendor_id' => 7,
            'capturada_por' => 5,
            'lineas' => [
                [
                    'request_line_id' => $lineIds[25],
                    'item_id' => 25,
                    'qty_oferta' => 8,
                    'uom_oferta' => 'PZA',
                    'precio_unitario' => 14,
                ],
                [
                    'request_line_id' => $lineIds[30],
                    'item_id' => 30,
                    'qty_oferta' => 3,
                    'uom_oferta' => 'KG',
                    'precio_unitario' => 78,
                ],
            ],
        ]);

        $this->assertSame('COTIZADA', $this->getRequestEstado($request['id']));
        $this->assertEquals( (8 * 14) + (3 * 78), $quote['total']);

        $approved = $service->approveQuote($quote['id'], userId: 9);
        $this->assertSame('APROBADA', $approved['estado']);
        $this->assertSame('APROBADA', $this->getRequestEstado($request['id']));

        $order = $service->issuePurchaseOrder($quote['id'], [
            'creado_por' => 11,
            'estado' => 'APROBADA',
        ]);

        $this->assertSame('ORDENADA', $this->getRequestEstado($request['id']));
        $this->assertSame('APROBADA', $order['estado']);
        $this->assertSame($quote['total'], $order['total']);
        $this->assertCount(2, $order['lineas']);
    }

    protected function getRequestEstado(int $requestId): string
    {
        return (string) DB::connection('pgsql')->table('purchase_requests')->where('id', $requestId)->value('estado');
    }
}
