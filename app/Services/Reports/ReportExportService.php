<?php

namespace App\Services\Reports;

use Carbon\Carbon;
use Illuminate\Http\Response;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportExportService
{
    /**
     * @param  array<string,float>  $kpis
     * @param  array<string,array<int,mixed>>  $charts
     */
    public function export(string $type, string $range, Carbon $from, Carbon $to, array $kpis, array $charts): Response|StreamedResponse
    {
        return $type === 'csv'
            ? $this->exportCsv($range, $from, $to, $kpis, $charts)
            : $this->exportPdf($range, $from, $to, $kpis, $charts);
    }

    protected function exportCsv(string $range, Carbon $from, Carbon $to, array $kpis, array $charts): StreamedResponse
    {
        $filename = sprintf('dashboard_%s_%s.csv', $range, now()->format('Ymd_His'));

        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ];

        $callback = function () use ($range, $from, $to, $kpis, $charts) {
            $output = fopen('php://output', 'w');
            // Añadir BOM para que se muestre correctamente en Excel
            fprintf($output, chr(0xEF).chr(0xBB).chr(0xBF));
            
            fputcsv($output, ['Dashboard Terrena ERP']);
            fputcsv($output, ['Rango', $range]);
            fputcsv($output, ['Desde', $from->toDateTimeString()]);
            fputcsv($output, ['Hasta', $to->toDateTimeString()]);
            fputcsv($output, []);
            
            fputcsv($output, ['KPIs']);
            fputcsv($output, ['Nombre', 'Valor']);
            
            foreach ($kpis as $key => $value) {
                $formattedValue = $this->formatValue($key, $value);
                fputcsv($output, [Str::headline(str_replace('_', ' ', $key)), $formattedValue]);
            }

            fputcsv($output, []);
            
            foreach ($charts as $key => $dataset) {
                fputcsv($output, [Str::headline(str_replace('_', ' ', $key))]);
                
                if (is_array($dataset) && count($dataset) > 0) {
                    $firstRow = reset($dataset);
                    if (is_array($firstRow)) {
                        // Si los datos son estructurados (con claves), incluir encabezados
                        fputcsv($output, array_keys($firstRow));
                        foreach ($dataset as $row) {
                            fputcsv($output, array_values((array) $row));
                        }
                    } else {
                        // Si los datos son simples, usar una columna
                        fputcsv($output, ['Valor']);
                        foreach ($dataset as $row) {
                            fputcsv($output, [(string)$row]);
                        }
                    }
                } else {
                    fputcsv($output, ['No hay datos disponibles']);
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

        // Generar contenido HTML para convertir a PDF
        $html = $this->buildHtmlForPdf($range, $from, $to, $kpis, $charts);

        // Intentar usar una librería de PDF si está disponible, o usar el método actual
        if (class_exists('Barryvdh\DomPDF\ServiceProvider')) {
            $pdf = app('dompdf.wrapper');
            $pdf->loadHTML($html);
            return $pdf->download($filename);
        } else {
            // Si no está instalada la librería, generamos un PDF básico
            $content = $this->buildMinimalPdf($range, $from, $to, $kpis, $charts);

            return response($content, 200, [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => "attachment; filename=\"{$filename}\"",
            ]);
        }
    }

    /**
     * Genera un HTML para el PDF
     *
     * @param  array<string,float>  $kpis
     * @param  array<string,array<int,mixed>>  $charts
     */
    protected function buildHtmlForPdf(string $range, Carbon $from, Carbon $to, array $kpis, array $charts): string
    {
        $html = '<!DOCTYPE html>';
        $html .= '<html>';
        $html .= '<head>';
        $html .= '<meta charset="utf-8">';
        $html .= '<title>Dashboard Reporte</title>';
        $html .= '<style>';
        $html .= 'body { font-family: Arial, sans-serif; margin: 20px; }';
        $html .= 'h1, h2 { color: #333; }';
        $html .= 'table { width: 100%; border-collapse: collapse; margin: 20px 0; }';
        $html .= 'th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }';
        $html .= 'th { background-color: #f2f2f2; }';
        $html .= '.header { background-color: #4e73df; color: white; padding: 10px; margin-bottom: 20px; }';
        $html .= '</style>';
        $html .= '</head>';
        $html .= '<body>';
        $html .= '<div class="header"><h1>Dashboard Terrena ERP</h1></div>';
        $html .= '<p><strong>Rango:</strong> ' . htmlspecialchars($range) . '</p>';
        $html .= '<p><strong>Desde:</strong> ' . htmlspecialchars($from->toDateTimeString()) . '</p>';
        $html .= '<p><strong>Hasta:</strong> ' . htmlspecialchars($to->toDateTimeString()) . '</p>';
        $html .= '<h2>KPIs</h2>';
        $html .= '<table>';
        $html .= '<thead><tr><th>Nombre</th><th>Valor</th></tr></thead>';
        $html .= '<tbody>';

        foreach ($kpis as $key => $value) {
            $formattedKey = Str::headline(str_replace('_', ' ', $key));
            $formattedValue = $this->formatValue($key, $value);
            $html .= '<tr><td>' . htmlspecialchars($formattedKey) . '</td><td>' . htmlspecialchars($formattedValue) . '</td></tr>';
        }

        $html .= '</tbody></table>';

        foreach ($charts as $key => $rows) {
            $html .= '<h2>' . htmlspecialchars(Str::headline(str_replace('_', ' ', $key))) . '</h2>';
            if (is_array($rows) && count($rows) > 0) {
                $html .= '<table>';
                $html .= '<thead><tr>';
                
                // Crear encabezados basados en las claves del primer elemento
                $firstRow = reset($rows);
                if (is_array($firstRow)) {
                    foreach (array_keys($firstRow) as $header) {
                        $html .= '<th>' . htmlspecialchars(Str::headline(str_replace('_', ' ', $header))) . '</th>';
                    }
                } else {
                    $html .= '<th>Valor</th>';
                }
                
                $html .= '</tr></thead>';
                $html .= '<tbody>';
                
                foreach ($rows as $row) {
                    $html .= '<tr>';
                    if (is_array($row)) {
                        foreach ($row as $cell) {
                            $html .= '<td>' . htmlspecialchars((string)$cell) . '</td>';
                        }
                    } else {
                        $html .= '<td>' . htmlspecialchars((string)$row) . '</td>';
                    }
                    $html .= '</tr>';
                }
                
                $html .= '</tbody></table>';
            } else {
                $html .= '<p>No hay datos disponibles</p>';
            }
        }

        $html .= '</body>';
        $html .= '</html>';

        return $html;
    }

    /**
     * Formatea valores según el tipo de KPI
     */
    protected function formatValue(string $key, float $value): string
    {
        if (Str::contains($key, ['ventas', 'compras', 'inventario', 'costo'])) {
            return '$' . number_format($value, 2);
        } elseif (Str::contains($key, ['merma', 'eficiencia'])) {
            return number_format($value, 1) . '%';
        } else {
            return number_format($value, 1);
        }
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
            $lines[] = sprintf('- %s: %s', Str::headline(str_replace('_', ' ', $key)), $this->formatValue($key, $value));
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
