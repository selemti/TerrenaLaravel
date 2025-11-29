<?php

namespace Tests\Feature\Reports;

use App\Exports\Reports\SalesExceptionsExport;
use App\Models\User;
use App\Services\Reports\SalesExceptionsReportService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\WithoutMiddleware;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Facades\Excel;
use Illuminate\Support\Facades\View;
use Mockery;
use Tests\TestCase;

class SalesExceptionsExportTest extends TestCase
{
    use WithoutMiddleware;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->withoutMiddleware();
        DB::shouldReceive('connection')
            ->with('pgsql')
            ->andReturnSelf();
        DB::shouldReceive('statement')->andReturnTrue();

        $this->user = User::make([
            'id' => 1,
            'name' => 'Test User',
            'email' => 'test@terrena.test',
        ]);
    }

    public function test_excel_export_includes_expected_sections_and_values(): void
    {
        if (! class_exists(\Maatwebsite\Excel\Facades\Excel::class)) {
            $this->markTestSkipped('maatwebsite/excel no está instalado en este entorno.');
        }

        [$records, $categories, $summary, $discountSummary] = $this->reportFixture();

        $this->mockReportService($records, $categories, $summary, $discountSummary);

        Excel::fake();

        $response = $this->actingAs($this->user)->get(route('reports.sales.exceptions.export.xlsx', [
            'start' => '2025-11-10',
            'end' => '2025-11-10',
            'branch' => 'CDMX',
            'terminal' => 'T01',
        ]));

        $response->assertOk();

        $expectedFilename = 'reporte_excepciones_20251110_20251110_cdmx_t01.xlsx';

        Excel::assertDownloaded($expectedFilename, function (SalesExceptionsExport $export) {
            $rows = collect($export->array());

            $this->assertTrue($rows->contains(['Resumen']));
            $this->assertTrue($rows->contains(fn ($row) => $row[0] === 'Impacto total' && (float) $row[1] === 339.2));
            $this->assertTrue($rows->contains(['Detalle por categoría']));
            $this->assertTrue($rows->contains(['Resumen de descuentos']));

            $detailIndex = $rows->search(fn ($row) => $row === ['Detalle de excepciones']);
            $this->assertNotFalse($detailIndex);

            $detailRows = $rows->slice($detailIndex + 2)->filter()->values();
            $this->assertCount(9, $detailRows);

            return true;
        });
    }

    public function test_pdf_export_generates_attachment_with_filters_in_filename(): void
    {
        if (! class_exists(\Dompdf\Options::class)) {
            $this->markTestSkipped('dompdf/dompdf no está instalado en este entorno.');
        }

        [$records, $categories, $summary, $discountSummary] = $this->reportFixture();

        $this->mockReportService($records, $categories, $summary, $discountSummary);

        $response = $this->actingAs($this->user)->get(route('reports.sales.exceptions.export.pdf', [
            'start' => '2025-11-10',
            'end' => '2025-11-10',
            'branch' => 'CDMX',
            'terminal' => 'T01',
        ]));

        $response->assertOk();
        $response->assertHeader('Content-Type', 'application/pdf');

        $disposition = $response->headers->get('Content-Disposition');
        $this->assertStringContainsString('reporte_excepciones_20251110_20251110_cdmx_t01.pdf', $disposition);
        $this->assertGreaterThan(500, strlen($response->getContent()));
        $this->assertTrue(View::exists('reports.exports.sales.exceptions'));
    }

    protected function mockReportService(Collection $records, Collection $categories, array $summary, Collection $discountSummary): void
    {
        $service = Mockery::mock(SalesExceptionsReportService::class);
        $service->shouldReceive('fetch')->once()->andReturn($records);
        $service->shouldReceive('summarize')->once()->andReturn([
            'records' => $records,
            'categories' => $categories,
            'summary' => $summary,
            'discounts' => [
                'summary' => $discountSummary,
            ],
        ]);
        $service->shouldReceive('getCategoryCatalog')->andReturn([]);

        $this->app->instance(SalesExceptionsReportService::class, $service);
    }

    protected function reportFixture(): array
    {
        $start = Carbon::parse('2025-11-10', 'America/Mexico_City');

        $records = collect();
        $categories = collect();
        $discountSummary = collect([
            [
                'name' => 'Cortesía Gerencia',
                'applications' => 3,
                'tickets' => 3,
                'total_amount' => 120.0,
                'average_amount' => 40.0,
                'scopes' => ['ticket' => 2, 'item' => 1],
            ],
            [
                'name' => 'Cupón Promoción',
                'applications' => 6,
                'tickets' => 6,
                'total_amount' => 45.2,
                'average_amount' => 7.53,
                'scopes' => ['ticket' => 4, 'item' => 2],
            ],
        ]);

        $baseRecord = [
            'folio_date' => $start->toDateString(),
            'branch_key' => 'CDMX',
            'terminal_id' => 'T01',
            'payment_total' => 200.0,
            'payment_adjustment_total' => 0.0,
            'notes' => ['Nota de ejemplo'],
            'discounts' => [
                ['name' => 'Promo', 'amount' => 10, 'applications' => 1, 'scope' => 'ticket'],
            ],
            'transactions' => [
                ['payment_type' => 'EFECTIVO', 'transaction_type' => 'PAGO', 'amount' => 200.0],
            ],
        ];

        $impacts = [
            ['ticket_id' => 101, 'category' => 'discount_100', 'net_total' => 0, 'impact' => 60.00],
            ['ticket_id' => 102, 'category' => 'discount_100', 'net_total' => 0, 'impact' => 62.00],
            ['ticket_id' => 103, 'category' => 'discount_100', 'net_total' => 0, 'impact' => 63.00],
            ['ticket_id' => 104, 'category' => 'discount_100', 'net_total' => 0, 'impact' => 63.00],
            ['ticket_id' => 201, 'category' => 'discount_high', 'net_total' => 120.00, 'impact' => 45.60],
            ['ticket_id' => 202, 'category' => 'discount_high', 'net_total' => 80.00, 'impact' => 12.40],
            ['ticket_id' => 203, 'category' => 'discount_high', 'net_total' => 100.00, 'impact' => 20.00],
            ['ticket_id' => 204, 'category' => 'discount_high', 'net_total' => 90.00, 'impact' => 13.20],
            ['ticket_id' => 301, 'category' => 'voided_with_payments', 'net_total' => 0, 'impact' => 0.00],
        ];

        foreach ($impacts as $row) {
            $records->push(array_merge($baseRecord, $row));
        }

        $categories->push([
            'key' => 'discount_100',
            'label' => 'Descuentos 100%',
            'description' => 'Tickets con descuento total',
            'count' => 4,
            'tickets' => 4,
            'impact' => 248.00,
            'impact_label' => 'Monto descontado',
            'rows' => $records->where('category', 'discount_100')->values(),
        ]);

        $categories->push([
            'key' => 'discount_high',
            'label' => 'Descuentos elevados',
            'description' => 'Descuentos mayores a umbral',
            'count' => 4,
            'tickets' => 4,
            'impact' => 91.20,
            'impact_label' => 'Descuento aplicado',
            'rows' => $records->where('category', 'discount_high')->values(),
        ]);

        $categories->push([
            'key' => 'voided_with_payments',
            'label' => 'Anulados con cobros',
            'description' => 'Tickets anulados con cobros',
            'count' => 1,
            'tickets' => 1,
            'impact' => 0.00,
            'impact_label' => 'Movimientos asociados',
            'rows' => $records->where('category', 'voided_with_payments')->values(),
        ]);

        $summary = [
            'total_records' => 9,
            'total_tickets' => 9,
            'impact_sum' => 339.20,
            'by_category' => $categories->map(fn (array $category) => [
                'key' => $category['key'],
                'label' => $category['label'],
                'count' => $category['count'],
                'tickets' => $category['tickets'],
                'impact' => $category['impact'],
            ])->values()->all(),
        ];

        return [$records, $categories, $summary, $discountSummary];
    }
}
