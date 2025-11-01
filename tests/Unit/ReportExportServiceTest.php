<?php

namespace Tests\Unit;

use App\Services\Reports\ReportExportService;
use Carbon\Carbon;
use Illuminate\Http\Response;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Tests\TestCase;

class ReportExportServiceTest extends TestCase
{
    public function test_it_generates_csv_response(): void
    {
        $service = new ReportExportService();
        $response = $service->export(
            type: 'csv',
            range: 'last_7_days',
            from: Carbon::parse('2025-11-01 00:00:00'),
            to: Carbon::parse('2025-11-07 23:59:59'),
            kpis: ['ventas_totales' => 1234.56],
            charts: ['ventas_por_dia' => [['fecha' => '01/11', 'total' => 100.0]]],
        );

        $this->assertInstanceOf(StreamedResponse::class, $response);
        $this->assertStringContainsString('text/csv', $response->headers->get('Content-Type'));
    }

    public function test_it_generates_pdf_response(): void
    {
        $service = new ReportExportService();
        $response = $service->export(
            type: 'pdf',
            range: 'last_7_days',
            from: Carbon::parse('2025-11-01 00:00:00'),
            to: Carbon::parse('2025-11-07 23:59:59'),
            kpis: ['ventas_totales' => 1234.56],
            charts: ['ventas_por_dia' => [['fecha' => '01/11', 'total' => 100.0]]],
        );

        $this->assertInstanceOf(Response::class, $response);
        $this->assertStringContainsString('application/pdf', $response->headers->get('Content-Type'));
        $this->assertNotEmpty($response->getContent());
        $this->assertStringStartsWith('%PDF', $response->getContent());
    }
}
