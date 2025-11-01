<?php

namespace App\Services\Reports;

use Carbon\Carbon;
use Illuminate\Http\Response;
use Illuminate\Support\Str;

class ReportExportService
{
    /**
     * @param  array<string,float>  $kpis
     * @param  array<string,array<int,mixed>>  $charts
     */
    public function export(string $type, string $range, Carbon $from, Carbon $to, array $kpis, array $charts): Response
    {
        return $type === 'csv'
            ? $this->exportCsv($range, $from, $to, $kpis, $charts)
            : $this->exportPdf($range, $from, $to, $kpis, $charts);
    }

    protected function exportCsv(string $range, Carbon $from, Carbon $to, array $kpis, array $charts): Response
    {
        $filename = sprintf('dashboard_%s_%s.csv', $range, now()->format('Ymd_His'));

        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ];

        $callback = function () use ($range, $from, $to, $kpis, $charts) {
            $output = fopen('php://output', 'w');
            fputcsv($output, ['Dashboard Terrena ERP']);
            fputcsv($output, ['Rango', $range]);
            fputcsv($output, ['Desde', $from->toDateTimeString()]);
            fputcsv($output, ['Hasta', $to->toDateTimeString()]);
            fputcsv($output, []);
            fputcsv($output, ['KPIs']);

            foreach ($kpis as $key => $value) {
                fputcsv($output, [Str::headline(str_replace('_', ' ', $key)), $value]);
            }

            fputcsv($output, []);
            fputcsv($output, ['Gráficas']);

            foreach ($charts as $key => $dataset) {
                fputcsv($output, [Str::headline(str_replace('_', ' ', $key))]);
                if (is_array($dataset)) {
                    foreach ($dataset as $row) {
                        fputcsv($output, array_values((array) $row));
                    }
                }
                fputcsv($output, []);
            }

            fclose($output);
        };

        return response()->stream($callback, 200, $headers);
    }

    protected function exportPdf(string $range, Carbon $from, Carbon $to, array $kpis, array $charts): Response
    {
        $filename = sprintf('dashboard_%s_%s.pdf', $range, now()->format('Ymd_His'));

        $content = $this->buildMinimalPdf($range, $from, $to, $kpis, $charts);

        return response($content, 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ]);
    }

    /**
     * Genera un PDF básico sin dependencias externas.
     *
     * @param  array<string,float>  $kpis
     * @param  array<string,array<int,mixed>>  $charts
     */
    protected function buildMinimalPdf(string $range, Carbon $from, Carbon $to, array $kpis, array $charts): string
    {
        $lines = [];
        $lines[] = 'Dashboard Terrena ERP';
        $lines[] = sprintf('Rango: %s', $range);
        $lines[] = sprintf('Desde: %s', $from->toDateTimeString());
        $lines[] = sprintf('Hasta: %s', $to->toDateTimeString());
        $lines[] = '';
        $lines[] = 'KPIs';

        foreach ($kpis as $key => $value) {
            $lines[] = sprintf('- %s: %s', Str::headline(str_replace('_', ' ', $key)), number_format($value, 2));
        }

        $lines[] = '';
        $lines[] = 'Gráficas';
        foreach ($charts as $key => $rows) {
            $lines[] = Str::headline(str_replace('_', ' ', $key));
            foreach ($rows as $row) {
                $values = implode(' | ', array_map(fn ($value) => is_numeric($value) ? number_format((float) $value, 2) : (string) $value, (array) $row));
                $lines[] = '  • ' . $values;
            }
            $lines[] = '';
        }

        $text = implode("\n", $lines);
        $text = str_replace(['(', ')'], ['\\(', '\\)'], $text);
        $text = str_replace("\r", '', $text);

        $contentStream = 'BT /F1 12 Tf 40 780 Td ';
        $chunks = explode("\n", $text);
        foreach ($chunks as $index => $chunk) {
            $escaped = str_replace(['\\', "\n"], ['\\\\', ''], $chunk);
            if ($index === 0) {
                $contentStream .= sprintf('(%s) Tj ', $escaped);
            } else {
                $contentStream .= sprintf('T* (%s) Tj ', $escaped);
            }
        }
        $contentStream .= 'ET';

        $objects = [];
        $objects[] = "1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n";
        $objects[] = "2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n";
        $objects[] = "3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj\n";
        $objects[] = sprintf("4 0 obj << /Length %d >> stream\n%s\nendstream endobj\n", strlen($contentStream), $contentStream);
        $objects[] = "5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n";

        $header = "%PDF-1.4\n";
        $buffer = $header;
        $offsets = [0];

        foreach ($objects as $object) {
            $offsets[] = strlen($buffer);
            $buffer .= $object;
        }

        $xrefOffset = strlen($buffer);
        $xref = sprintf("xref\n0 %d\n", count($offsets));
        $xref .= "0000000000 65535 f \n";

        for ($i = 1; $i < count($offsets); $i++) {
            $xref .= sprintf("%010d 00000 n \n", $offsets[$i]);
        }

        $trailer = "trailer << /Size " . count($offsets) . " /Root 1 0 R >>\n";
        $trailer .= "startxref\n{$xrefOffset}\n%%EOF";

        return $buffer . $xref . $trailer;
    }
}
