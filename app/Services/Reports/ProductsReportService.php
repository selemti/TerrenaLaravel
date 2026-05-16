<?php

namespace App\Services\Reports;

use App\Adapters\FloreantPos\FloreantPosAdapter;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class ProductsReportService
{
    public function __construct(private readonly FloreantPosAdapter $pos) {}

    /**
     * Obtiene datos de productos vendidos por mes
     */
    public function fetchProductsByMonth(
        Carbon $start,
        Carbon $end,
        ?array $branchIds = null,
        ?array $terminalIds = null,
        ?string $groupBy = 'month' // month, category, product
    ): Collection {
        return match ($groupBy) {
            'category' => $this->pos->getProductSalesByCategory($start, $end, $branchIds, $terminalIds)
                ->map(function ($row) {
                    $row->ingreso_total_formateado = '$'.number_format($row->ingreso_total, 2);
                    $row->precio_promedio_formateado = '$'.number_format($row->precio_promedio, 2);

                    return $row;
                }),
            'product' => $this->pos->getProductSalesByProduct($start, $end, $branchIds, $terminalIds)
                ->map(function ($row) {
                    $row->ingreso_total_formateado = '$'.number_format($row->ingreso_total, 2);
                    $row->precio_promedio_formateado = '$'.number_format($row->precio_promedio, 2);
                    $row->precio_minimo_formateado = '$'.number_format($row->precio_minimo, 2);
                    $row->precio_maximo_formateado = '$'.number_format($row->precio_maximo, 2);

                    return $row;
                }),
            default => $this->pos->getProductSalesByMonth($start, $end, $branchIds, $terminalIds)
                ->map(function ($row) {
                    $row->mes_formateado = $this->formatMonth($row->numero_mes, $row->anio);
                    $row->precio_promedio_formateado = number_format($row->precio_promedio, 2);
                    $row->ingreso_total_formateado = '$'.number_format($row->ingreso_total, 2);

                    return $row;
                }),
        };
    }

    /**
     * Obtendiendo datos de productos por día para análisis detallado
     */
    public function fetchDailyProducts(
        Carbon $start,
        Carbon $end,
        ?array $branchIds = null,
        ?array $terminalIds = null
    ): Collection {
        return $this->pos->getDailyProductSales($start, $end, $branchIds, $terminalIds)
            ->map(function ($row) {
                return (object) [
                    'fecha' => Carbon::parse($row->folio_date)->format('d/m/Y'),
                    'folio_date' => Carbon::parse($row->folio_date),
                    'categoria' => $row->category_name,
                    'producto' => $row->item_name,
                    'unidades' => (int) $row->item_count,
                    'precio_unitario' => (float) $row->item_price,
                    'total' => (float) $row->total_price,
                    'sucursal' => $row->branch_key,
                    'terminal' => $row->terminal_id,
                ];
            });
    }

    /**
     * Obtiene resumen para KPIs
     */
    public function getSummary(Collection $data): array
    {
        $minMes = $data->min('mes');
        $maxMes = $data->max('mes');

        return [
            'total_unidades' => $data->sum('unidades_vendidas'),
            'total_ingresos' => $data->sum('ingreso_total'),
            'total_tickets' => $data->sum('tickets_totales'),
            'productos_unicos' => $data->unique('producto')->count(),
            'categorias_unicas' => $data->unique('categoria')->count(),
            'precio_promedio_general' => $data->avg('precio_promedio'),
            'fecha_inicio' => $minMes ? Carbon::parse($minMes)->format('F Y') : 'N/D',
            'fecha_fin' => $maxMes ? Carbon::parse($maxMes)->format('F Y') : 'N/D',
            'meses' => $data->count(),
        ];
    }

    /**
     * Obtiene totales detallados usando metodología JasperReports (MenuItems vs Modifiers)
     */
    /**
     * Determina si se debe usar el modelo financiero canónico
     */
    protected function isCanonMode(): bool
    {
        return request()->query('mode') === 'canon'
            || config('finance.use_canon_mode', false);
    }

    /**
     * Obtiene totales detallados usando metodología JasperReports vs Canon SSOT
     */
    public function getJasperReportsTotals(Carbon $start, Carbon $end, ?array $branchIds = null, ?array $terminalIds = null): array
    {
        $isCanon = $this->isCanonMode();

        $raw = $this->pos->getJasperTotals($start, $end, $branchIds, $terminalIds);

        $res = [
            'is_canon_mode' => $isCanon,
            'items_neto_todos' => $raw['items_neto'],
            'descuentos_todos' => $raw['descuentos_items'],
            'total_tickets_todos' => $raw['total_tickets'],
            'items_neto_excluding100' => $raw['items_neto_excluding_100'],
            'descuentos_excluding100' => $raw['descuentos_excluding_100'],
            'tickets_excluding100' => $raw['tickets_excluding_100'],
            'modificadores_total' => $raw['modificadores_total'],
            'canon_neto' => $raw['canon_neto'],
            'canon_tickets' => $raw['canon_tickets'],
        ];

        $res['net_sales_current'] = $isCanon ? $res['canon_neto'] : $res['items_neto_todos'];
        $res['gran_total_current'] = $res['net_sales_current'] + $res['modificadores_total'];

        $res['items_neto_todos_formateado'] = '$'.number_format($res['items_neto_todos'], 2);
        $res['net_sales_jasper_formateado'] = '$'.number_format($res['net_sales_current'], 2);
        $res['gran_total_jasper_formateado'] = '$'.number_format($res['gran_total_current'], 2);
        $res['nota_metodologia'] = $isCanon ? 'Modo CANON (SSOT Transactions)' : 'Modo LEGACY (Arithmética vulnerable)';

        return $res;
    }

    /**
     * Formatea mes para mostrar
     */
    protected function formatMonth($month, $year): string
    {
        $meses = [
            1 => 'Enero', 2 => 'Febrero', 3 => 'Marzo', 4 => 'Abril',
            5 => 'Mayo', 6 => 'Junio', 7 => 'Julio', 8 => 'Agosto',
            9 => 'Septiembre', 10 => 'Octubre', 11 => 'Noviembre', 12 => 'Diciembre',
        ];

        return $meses[$month] ?? 'Mes '.$month.' '.$year;
    }

    /**
     * Obtiene datos de comparación mes a mes
     */
    public function getMonthComparison(Carbon $start, Carbon $end): Collection
    {
        $results = $this->pos->getMonthComparisonData($start, $end);

        if ($results->isEmpty()) {
            return collect([]);
        }

        return collect($results)->map(function ($row, $index) use ($results) {
            $previousRow = $results[$index - 1] ?? null;

            $row->variacion_unidades = $previousRow
                ? $row->unidades - $previousRow->unidades
                : 0;

            $row->variacion_porcentual_unidades = $previousRow && $previousRow->unidades > 0
                ? round((($row->unidades / $previousRow->unidades - 1) * 100), 2)
                : 0;

            $row->variacion_ingresos = $previousRow
                ? $row->ingresos - $previousRow->ingresos
                : 0;

            $row->variacion_porcentual_ingresos = $previousRow && $previousRow->ingresos > 0
                ? round((($row->ingresos / $previousRow->ingresos - 1) * 100), 2)
                : 0;

            $row->tendencia_unidades = $row->variacion_unidades > 0 ? '📈' : ($row->variacion_unidades < 0 ? '📉' : '➡');
            $row->tendencia_ingresos = $row->variacion_ingresos > 0 ? '📈' : ($row->variacion_ingresos < 0 ? '📉' : '➡');

            return $row;
        });
    }
}
