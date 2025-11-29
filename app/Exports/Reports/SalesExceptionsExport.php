<?php

namespace App\Exports\Reports;

use Carbon\Carbon;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithTitle;

class SalesExceptionsExport implements FromArray, ShouldAutoSize, WithTitle
{
    public function __construct(
        protected Carbon $start,
        protected Carbon $end,
        protected Collection $records,
        protected Collection $categories,
        protected array $summary,
        protected array $branches,
        protected array $terminals,
        protected Collection $discountSummary,
    ) {
    }

    public function array(): array
    {
        $output = [];
        $output[] = ['Excepciones de ventas - Terrena ERP'];
        $output[] = ['Fecha inicial', $this->start->format('Y-m-d')];
        $output[] = ['Fecha final', $this->end->format('Y-m-d')];
        $output[] = ['Sucursales', $this->stringify($this->branches) ?? 'Todas'];
        $output[] = ['Terminales', $this->stringify($this->terminals) ?? 'Todas'];
        $output[] = ['Generado', now('America/Mexico_City')->format('Y-m-d H:i')];
        $output[] = [];

        $output[] = ['Resumen'];
        $output[] = ['Registros', $this->summary['total_records'] ?? 0];
        $output[] = ['Tickets únicos', $this->summary['total_tickets'] ?? 0];
        $output[] = ['Impacto total', round((float) ($this->summary['impact_sum'] ?? 0), 2)];
        $output[] = [];

        if (! empty($this->summary['by_category'])) {
            $output[] = ['Detalle por categoría'];
            $output[] = ['Categoría', 'Registros', 'Tickets', 'Impacto'];
            foreach ($this->summary['by_category'] as $category) {
                $output[] = [
                    $category['label'] ?? $category['key'] ?? 'N/D',
                    $category['count'] ?? 0,
                    $category['tickets'] ?? 0,
                    round((float) ($category['impact'] ?? 0), 2),
                ];
            }
            $output[] = [];
        }

        if ($this->discountSummary->isNotEmpty()) {
            $output[] = ['Resumen de descuentos'];
            $output[] = ['Nombre', 'Aplicaciones', 'Tickets', 'Total', 'Promedio', 'Ticket', 'Item'];
            foreach ($this->discountSummary as $discount) {
                $scopes = $discount['scopes'] ?? [];
                $output[] = [
                    $discount['name'] ?? 'N/D',
                    $discount['applications'] ?? 0,
                    $discount['tickets'] ?? 0,
                    round((float) ($discount['total_amount'] ?? 0), 2),
                    round((float) ($discount['average_amount'] ?? 0), 2),
                    $scopes['ticket'] ?? 0,
                    $scopes['item'] ?? 0,
                ];
            }
            $output[] = [];
        }

        $categoryLabels = $this->categories
            ->mapWithKeys(fn (array $category) => [$category['key'] ?? '' => $category['label'] ?? ($category['key'] ?? '')])
            ->filter()
            ->toArray();

        $output[] = ['Detalle de excepciones'];
        $output[] = [
            'Fecha',
            'Sucursal',
            'Ticket',
            'Terminal',
            'Neto',
            'Cobros',
            'Ajustes',
            'Impacto',
            'Categoría',
            'Notas',
            'Descuentos',
            'Movimientos',
        ];

        foreach ($this->records as $record) {
            $notes = collect($record['notes'] ?? [])->implode(' | ');
            $discounts = collect($record['discounts'] ?? [])->map(function (array $discount) {
                $scope = ($discount['scope'] ?? 'ticket') === 'item' ? 'Item' : 'Ticket';
                $applications = (int) ($discount['applications'] ?? 0);
                $applicationsLabel = $applications > 1 ? ' x'.$applications : '';

                return sprintf(
                    '%s (%s) %s%s',
                    $discount['name'] ?? 'Descuento',
                    $scope,
                    $this->money($discount['amount'] ?? 0),
                    $applicationsLabel
                );
            })->implode(' | ');

            $transactions = collect($record['transactions'] ?? [])->map(function (array $tx) {
                $label = trim($tx['payment_type'] ?? '');
                if (! empty($tx['transaction_type']) && $tx['transaction_type'] !== $tx['payment_type']) {
                    $label .= ' / '.trim((string) $tx['transaction_type']);
                }

                return sprintf('%s %s', $label !== '' ? $label : 'SIN TIPO', $this->money($tx['amount'] ?? 0));
            })->implode(' | ');

            $output[] = [
                $record['folio_date'] ?? '',
                $record['branch_key'] ?? '',
                $record['ticket_id'] ?? '',
                $record['terminal_id'] ?? '',
                $this->money($record['net_total'] ?? 0),
                $this->money($record['payment_total'] ?? 0),
                $this->money($record['payment_adjustment_total'] ?? 0),
                $this->money($record['impact'] ?? 0),
                $categoryLabels[$record['category'] ?? ''] ?? ($record['category'] ?? ''),
                $notes,
                $discounts,
                $transactions,
            ];
        }

        return $output;
    }

    public function title(): string
    {
        return 'Excepciones de ventas';
    }

    protected function stringify(array $values): ?string
    {
        $normalized = collect($values)
            ->map(fn ($value) => trim((string) $value))
            ->filter()
            ->values();

        return $normalized->isEmpty() ? null : $normalized->implode(',');
    }

    protected function money(float $value): float
    {
        return round($value, 2);
    }
}
