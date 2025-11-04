<?php

namespace App\Exports\Reports;

use Carbon\Carbon;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithTitle;

class SalesMixExport implements FromArray, ShouldAutoSize, WithTitle
{
    protected Carbon $start;
    protected Carbon $end;
    protected Collection $rows;
    protected array $summary;
    protected ?string $branch;

    public function __construct(Carbon $start, Carbon $end, Collection $rows, array $summary, ?string $branch = null)
    {
        $this->start = $start;
        $this->end = $end;
        $this->rows = $rows;
        $this->summary = $summary;
        $this->branch = $branch;
    }

    public function array(): array
    {
        $output = [];
        $output[] = ['Mix de ventas Terrena ERP'];
        $output[] = ['Fecha inicial', $this->start->format('Y-m-d')];
        $output[] = ['Fecha final', $this->end->format('Y-m-d')];
        $output[] = ['Sucursal', $this->branch ?? 'Todas'];
        $output[] = ['Generado', now('America/Mexico_City')->format('Y-m-d H:i')];
        $output[] = [];

        $output[] = ['Fecha', 'Sucursal', 'Forma de pago', 'Monto', 'Participación %'];
        $totalGeneral = (float) ($this->summary['total_general'] ?? 0);

        foreach ($this->rows as $row) {
            $amount = (float) ($row->total ?? 0);
            $percentage = $totalGeneral > 0 ? round(($amount / $totalGeneral) * 100, 2) : 0.0;

            $output[] = [
                isset($row->report_date) ? (string) $row->report_date : $this->start->format('Y-m-d'),
                $row->branch_key ?? $row->branch ?? $row->branch_name ?? 'N/D',
                $row->normalized_payment ?? $row->payment_method ?? 'N/D',
                round($amount, 2),
                $percentage,
            ];
        }

        $output[] = [];
        $output[] = ['TOTAL', '', '', round($totalGeneral, 2), 100];

        $payments = collect($this->summary['payments'] ?? [])->values();
        if ($payments->isNotEmpty()) {
            $output[] = [];
            $output[] = ['Resumen por forma de pago'];
            $output[] = ['Forma', 'Monto', 'Participación %'];

            foreach ($payments as $payment) {
                $output[] = [
                    $payment['label'] ?? $payment['key'] ?? 'N/D',
                    round((float) ($payment['amount'] ?? 0), 2),
                    round((float) ($payment['percentage'] ?? 0), 2),
                ];
            }
        }

        $branches = collect($this->summary['branches'] ?? [])->values();
        if ($branches->isNotEmpty()) {
            $output[] = [];
            $output[] = ['Resumen por sucursal'];
            $output[] = ['Sucursal', 'Monto', 'Participación %'];

            foreach ($branches as $branch) {
                $output[] = [
                    $branch['label'] ?? $branch['key'] ?? 'N/D',
                    round((float) ($branch['amount'] ?? 0), 2),
                    round((float) ($branch['percentage'] ?? 0), 2),
                ];
            }
        }

        return $output;
    }

    public function title(): string
    {
        return 'Mix de ventas';
    }
}
