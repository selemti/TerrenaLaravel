<?php

namespace Tests\Unit\Services\Reports;

use App\Services\Reports\SalesExceptionsReportService;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Mockery;
use Tests\TestCase;

class SalesExceptionsReportServiceTest extends TestCase
{
    public function test_fetch_returns_correct_structure(): void
    {
        $start = Carbon::parse('2025-11-10', 'America/Mexico_City');
        $end = Carbon::parse('2025-11-10', 'America/Mexico_City');

        $service = Mockery::mock(SalesExceptionsReportService::class)
            ->makePartial()
            ->shouldAllowMockingProtectedMethods();

        $ticketRow = (object) [
            'ticket_id' => 101,
            'folio_date' => '2025-11-10',
            'branch_key' => 'CDMX',
            'terminal_id' => 'T01',
            'paid_flag' => false,
            'voided_flag' => false,
            'settled_flag' => false,
            'wasted_flag' => false,
            'refunded_flag' => false,
            'reopened_flag' => false,
            'ticket_status' => 'CLOSED',
            'ticket_type' => 'SALE',
            'daily_folio' => 5,
            'gross_total' => 150.0,
            'sub_total' => 150.0,
            'total_tax' => 0.0,
            'service_charge' => 0.0,
            'delivery_charge' => 0.0,
            'paid_amount_flag' => 0.0,
            'discount_total' => 30.0,
            'net_total_raw' => 120.0,
            'discount_total' => 30.0,
        ];

        $service->shouldReceive('fetchTickets')
            ->once()
            ->andReturn(collect([$ticketRow]));

        $service->shouldReceive('loadPaymentSummary')
            ->once()
            ->andReturn(collect([
                101 => [
                    'payment_total' => 80.0,
                    'payment_adjustment_total' => 0.0,
                    'refund_total' => 0.0,
                    'void_total' => 0.0,
                    'recorded_total' => 80.0,
                    'tx_count' => 1,
                    'payment_positive_count' => 1,
                    'payment_adjustment_count' => 0,
                ],
            ]));

        $service->shouldReceive('loadTransactionDetails')
            ->once()
            ->andReturn(collect([
                101 => collect([['payment_type' => 'CASH', 'amount' => 80.0]]),
            ]));

        $discountsByTicket = collect([
            101 => collect([
                ['name' => 'Promo', 'amount' => 10.0, 'scope' => 'ticket', 'type' => 'percent', 'applications' => 1],
            ]),
        ]);

        $discountSummary = collect([
            ['name' => 'Promo', 'applications' => 1, 'tickets' => 1, 'total_amount' => 10.0, 'average_amount' => 10.0, 'scopes' => ['ticket' => 1, 'item' => 0]],
        ]);

        $service->shouldReceive('loadDiscounts')
            ->once()
            ->andReturn([$discountsByTicket, $discountSummary]);

        $service->shouldReceive('loadItems')
            ->once()
            ->andReturn(collect([
                101 => collect([
                    ['name' => 'Producto', 'group' => 'Alimentos', 'quantity' => 1, 'unit_price' => 150, 'discount_amount' => 30, 'total_amount' => 120],
                ]),
            ]));

        $result = $service->fetch($start, $end, [
            'branch_ids' => ['cdmx'],
            'terminal_ids' => ['T01'],
        ]);

        $this->assertCount(1, $result);
        $first = $result->first();

        $this->assertSame(101, $first['ticket_id']);
        $this->assertSame('2025-11-10', $first['folio_date']);
        $this->assertSame('CDMX', $first['branch_key']);
        $this->assertSame('T01', $first['terminal_id']);
        $this->assertSame(120.0, $first['net_total']);
        $this->assertSame(80.0, $first['payment_total']);
        $this->assertNotEmpty($first['discounts']);
        $this->assertNotEmpty($first['items']);
        $this->assertNotEmpty($first['transactions']);
    }

    public function test_summarize_classifies_tickets_into_categories(): void
    {
        $service = new SalesExceptionsReportServiceProbe();
        $tickets = collect([
            // Descuento 100%
            [
                'ticket_id' => 1,
                'gross_total' => 100.0,
                'discount_total' => 100.0,
                'net_total' => 0.0,
                'payment_total' => 0.0,
                'payment_adjustment_total' => 0.0,
                'paid_flag' => false,
                'voided_flag' => false,
            ],
            // Descuento alto
            [
                'ticket_id' => 2,
                'gross_total' => 200.0,
                'discount_total' => 60.0,
                'net_total' => 140.0,
                'payment_total' => 0.0,
                'payment_adjustment_total' => 0.0,
                'paid_flag' => false,
                'voided_flag' => false,
            ],
            // Cerrado sin pago
            [
                'ticket_id' => 3,
                'gross_total' => 90.0,
                'discount_total' => 0.0,
                'net_total' => 90.0,
                'payment_total' => 0.0,
                'payment_adjustment_total' => 0.0,
                'paid_flag' => true,
                'voided_flag' => false,
            ],
            // Anulado con cobros
            [
                'ticket_id' => 4,
                'gross_total' => 0.0,
                'discount_total' => 0.0,
                'net_total' => 0.0,
                'payment_total' => 40.0,
                'payment_adjustment_total' => 0.0,
                'paid_flag' => false,
                'voided_flag' => true,
                'refund_total' => 0.0,
                'void_total' => 0.0,
                'tx_count' => 1,
            ],
            // Diferencia pagos vs neto
            [
                'ticket_id' => 5,
                'gross_total' => 120.0,
                'discount_total' => 0.0,
                'net_total' => 120.0,
                'payment_total' => 60.0,
                'payment_adjustment_total' => 0.0,
                'paid_flag' => true,
                'voided_flag' => false,
            ],
        ]);

        $summary = $service->summarize($tickets);

        $categories = $summary['categories']->pluck('key')->all();

        $this->assertContains('discount_100', $categories);
        $this->assertContains('discount_high', $categories);
        $this->assertContains('unpaid_closed', $categories);
        $this->assertContains('voided_with_payments', $categories);
        $this->assertContains('payment_mismatch', $categories);

        $this->assertSame(6, $summary['summary']['total_records']);
        $this->assertSame(5, $summary['summary']['total_tickets']);
        $this->assertSame(490.0, $summary['summary']['impact_sum']);
    }

    public function test_helper_methods_normalize_and_format(): void
    {
        $service = new SalesExceptionsReportServiceProbe();

        $this->assertSame(['CDMX', 'MTY'], $service->callNormalizeBranchFilter([' cdmx ', 'mty', 'cdmx']));
        $this->assertSame(['T01', 'T02'], $service->callNormalizeFilter([' T01', 'T02', 'T01 ']));
        $this->assertSame(10.12, $service->callRound(10.1234));
        $this->assertSame('$10.12', $service->callFormatMoney(10.1234));
    }

    public function test_ticket_can_generate_multiple_exceptions(): void
    {
        $service = new SalesExceptionsReportServiceProbe();

        $ticket = [
            'ticket_id' => 10,
            'folio_date' => '2025-11-10',
            'branch_key' => 'CDMX',
            'terminal_id' => 'T01',
            'gross_total' => 200.0,
            'discount_total' => 60.0,
            'net_total' => 140.0,
            'payment_total' => 40.0,
            'payment_adjustment_total' => 0.0,
            'paid_flag' => true,
            'voided_flag' => false,
        ];

        $discounts = collect([
            ['name' => 'Promo', 'scope' => 'ticket', 'type' => 'percent', 'applications' => 1, 'amount' => 60.0],
        ]);

        $records = $service->callClassifyTicket($ticket, $discounts);

        $categories = $records->pluck('category')->all();

        $this->assertContains('discount_high', $categories);
        $this->assertContains('payment_mismatch', $categories);
    }

    public function test_discount_summary_groups_by_name(): void
    {
        $service = new SalesExceptionsReportServiceProbe();

        $discountsByTicket = collect([
            1 => collect([
                ['ticket_id' => 1, 'name' => 'Cortesía', 'scope' => 'ticket', 'type' => 'percent', 'applications' => 1, 'amount' => 30.0],
                ['ticket_id' => 1, 'name' => 'Cortesía', 'scope' => 'ticket', 'type' => 'percent', 'applications' => 1, 'amount' => 20.0],
            ]),
            2 => collect([
                ['ticket_id' => 2, 'name' => 'Cupón', 'scope' => 'item', 'type' => 'fixed', 'applications' => 2, 'amount' => 15.0],
                ['ticket_id' => 2, 'name' => 'Cortesía', 'scope' => 'ticket', 'type' => 'percent', 'applications' => 1, 'amount' => 10.0],
            ]),
        ]);

        $summary = $service->callSummarizeDiscounts($discountsByTicket);

        $this->assertCount(2, $summary);

        $cortesia = $summary->firstWhere('name', 'Cortesía');
        $cupon = $summary->firstWhere('name', 'Cupón');

        $this->assertSame(2, $cortesia['tickets']);
        $this->assertSame(60.0, $cortesia['total_amount']);
        $this->assertSame(30.0, $cortesia['average_amount']);
        $this->assertSame(['ticket' => 3, 'item' => 0], $cortesia['scopes']);

        $this->assertSame(1, $cupon['tickets']);
        $this->assertSame(15.0, $cupon['total_amount']);
        $this->assertSame(15.0, $cupon['average_amount']);
        $this->assertSame(['ticket' => 0, 'item' => 1], $cupon['scopes']);
    }
}

/**
 * Helper class to expose protected methods for testing.
 */
class SalesExceptionsReportServiceProbe extends SalesExceptionsReportService
{
    public function callNormalizeBranchFilter(array $branches): array
    {
        return $this->normalizeBranchFilter($branches);
    }

    public function callNormalizeFilter(array $values): array
    {
        return $this->normalizeFilter($values);
    }

    public function callRound(float $value): float
    {
        return $this->round($value);
    }

    public function callFormatMoney(float $value): string
    {
        return $this->formatMoney($value);
    }

    public function callClassifyTicket(array $ticket, Collection $discounts): Collection
    {
        return $this->classifyTicket($ticket, $discounts);
    }

    public function callSummarizeDiscounts(Collection $discountsByTicket): Collection
    {
        return $this->summarizeDiscounts($discountsByTicket);
    }
}
