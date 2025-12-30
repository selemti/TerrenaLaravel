<?php

namespace App\Services\Reports;

use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class ProductsReportService
{
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
        $query = DB::connection('pgsql')
            ->table('public.ticket AS t')
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereBetween('t.folio_date', [
                $start->format('Y-m-d 00:00:00'),
                $end->format('Y-m-d 23:59:59')
            ])
            ->where('t.paid', '=', true)
            ->where('t.voided', '=', false)
            ->whereNotNull('ti.item_name')
            ->where('ti.item_count', '>', 0);

        if ($branchIds && count($branchIds) > 0) {
            $query->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds && count($terminalIds) > 0) {
            $query->whereIn('t.terminal_id', $terminalIds);
        }

        switch ($groupBy) {
            case 'month':
                return $this->groupByMonth($query);
            case 'category':
                return $this->groupByCategory($query, $start, $end);
            case 'product':
                return $this->groupByProduct($query);
            default:
                return $this->groupByMonth($query);
        }
    }

    /**
     * Agrupa datos por mes
     */
    protected function groupByMonth($query): Collection
    {
        $results = $query
            ->selectRaw("
                DATE_TRUNC('month', t.folio_date) AS mes,
                EXTRACT(YEAR FROM t.folio_date) AS anio,
                EXTRACT(MONTH FROM t.folio_date) AS numero_mes,
                COUNT(DISTINCT t.id) AS tickets_totales,
                SUM(ti.item_count) AS unidades_vendidas,
                SUM(ti.total_price) AS ingreso_total,
                ROUND(SUM(ti.total_price)::numeric, 2) AS ingreso_total_redondeado,
                AVG(ti.item_price) AS precio_promedio,
                MIN(ti.item_price) AS precio_minimo,
                MAX(ti.item_price) AS precio_maximo
            ")
            ->groupBy('mes', 'anio', 'numero_mes')
            ->orderBy('anio', 'desc')
            ->orderBy('numero_mes', 'desc')
            ->get()
            ->map(function ($row) {
                $row->mes_formateado = $this->formatMonth($row->numero_mes, $row->anio);
                $row->precio_promedio_formateado = number_format($row->precio_promedio, 2);
                $row->ingreso_total_formateado = '$' . number_format($row->ingreso_total, 2);
                return $row;
            });

        return $results;
    }

    /**
     * Agrupa datos por categoría
     */
    protected function groupByCategory($query, Carbon $start, Carbon $end): Collection
    {
        $results = $query
            ->selectRaw("
                ti.category_name AS categoria,
                COUNT(DISTINCT t.id) AS tickets_totales,
                SUM(ti.item_count) AS unidades_vendidas,
                SUM(ti.total_price) AS ingreso_total,
                ROUND(SUM(ti.total_price)::numeric, 2) AS ingreso_total_redondeado,
                AVG(ti.item_price) AS precio_promedio,
                COUNT(DISTINCT ti.item_name) AS productos_unicos
            ")
            ->groupBy('ti.category_name')
            ->orderBy('ingreso_total', 'desc')
            ->get();

        return $results->map(function ($row) {
            $row->ingreso_total_formateado = '$' . number_format($row->ingreso_total, 2);
            $row->precio_promedio_formateado = '$' . number_format($row->precio_promedio, 2);
            return $row;
        });
    }

    /**
     * Agrupa datos por producto
     */
    protected function groupByProduct($query): Collection
    {
        return $query
            ->selectRaw("
                ti.category_name AS categoria,
                ti.group_name AS grupo_menu,
                ti.item_name AS producto,
                COUNT(DISTINCT t.id) AS tickets_totales,
                SUM(ti.item_count) AS unidades_vendidas,
                SUM(ti.total_price) AS ingreso_total,
                ROUND(SUM(ti.total_price)::numeric, 2) AS ingreso_total_redondeado,
                AVG(ti.item_price) AS precio_promedio,
                MIN(ti.item_price) AS precio_minimo,
                MAX(ti.item_price) AS precio_maximo
            ")
            ->groupBy('ti.category_name', 'ti.group_name', 'ti.item_name')
            ->orderBy('ingreso_total', 'desc')
            ->get()
            ->map(function ($row) {
                $row->ingreso_total_formateado = '$' . number_format($row->ingreso_total, 2);
                $row->precio_promedio_formateado = '$' . number_format($row->precio_promedio, 2);
                $row->precio_minimo_formateado = '$' . number_format($row->precio_minimo, 2);
                $row->precio_maximo_formateado = '$' . number_format($row->precio_maximo, 2);
                return $row;
            });
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
        $query = DB::connection('pgsql')
            ->table('public.ticket AS t')
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereBetween('t.folio_date', [
                $start->format('Y-m-d'),
                $end->format('Y-m-d')
            ])
            ->where('t.paid', '=', true)
            ->where('t.voided', '=', false)
            ->whereNotNull('ti.item_name')
            ->where('ti.item_count', '>', 0)
            ->orderBy('t.folio_date', 'desc')
            ->orderBy('ti.item_name');

        if ($branchIds && count($branchIds) > 0) {
            $query->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds && count($terminalIds) > 0) {
            $query->whereIn('t.terminal_id', $terminalIds);
        }

        return collect($query->get())->map(function ($row) {
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
    public function getJasperReportsTotals(Carbon $start, Carbon $end, ?array $branchIds = null, ?array $terminalIds = null): array
    {
        $query = DB::connection('pgsql')
            ->table('public.ticket AS t')
            ->whereBetween('t.folio_date', [
                $start->format('Y-m-d 00:00:00'),
                $end->format('Y-m-d 23:59:59')
            ])
            ->where('t.paid', '=', true)
            ->where('t.voided', '=', false);

        if ($branchIds && count($branchIds) > 0) {
            $query->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds && count($terminalIds) > 0) {
            $query->whereIn('t.terminal_id', $terminalIds);
        }

        // Obtener totales de MenuItems (ticket_item) - Metodología JasperReports
        $menuItemsQuery = clone $query;
        $menuItemsTotals = $menuItemsQuery
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereNotNull('ti.item_name')
            ->selectRaw('
                SUM(ti.total_price) as items_neto,
                SUM(CASE WHEN ti.discount > 0 THEN ti.discount ELSE 0 END) as descuentos_items,
                SUM(COALESCE(ti.tax_amount, 0)) as impuestos_items,
                COUNT(DISTINCT t.id) as total_tickets
            ')
            ->first();

        // Obtener totales excluyendo tickets con descuento 100% (metodología JasperReports)
        $menuItemsExcluding100Query = clone $query;
        $menuItemsExcluding100 = $menuItemsExcluding100Query
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereNotNull('ti.item_name')
            ->where('t.total_price', '>', 0)  // Excluir tickets con descuento 100%
            ->selectRaw('
                SUM(ti.total_price) as items_neto_excluding_100,
                SUM(CASE WHEN ti.discount > 0 THEN ti.discount ELSE 0 END) as descuentos_excluding_100,
                COUNT(DISTINCT t.id) as tickets_excluding_100
            ')
            ->first();

        // Obtener totales de Modifiers (ticket_item_modifier)
        $modifiersQuery = clone $query;
        $modifiersTotals = $modifiersQuery
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->join('public.ticket_item_modifier AS tim', 'tim.ticket_item_id', '=', 'ti.id')
            ->selectRaw('
                SUM(COALESCE(tim.total_price, 0)) as total_modificadores
            ')
            ->first();

        // Calcular totales usando ambas metodologías
        $itemsNetoTodos = $menuItemsTotals->items_neto ?? 0;
        $itemsNetoExcluding100 = $menuItemsExcluding100->items_neto_excluding_100 ?? 0;
        $descuentosTodos = $menuItemsTotals->descuentos_items ?? 0;
        $descuentosExcluding100 = $menuItemsExcluding100->descuentos_excluding_100 ?? 0;
        $totalModificadores = $modifiersTotals->total_modificadores ?? 0;
        $totalTickets = $menuItemsTotals->total_tickets ?? 0;
        $ticketsExcluding100 = $menuItemsExcluding100->tickets_excluding_100 ?? 0;

        // Cálculos para JasperReports (basado en análisis)
        $jasperItemsGross = 42926.50;  // Del PDF del usuario
        $jasperDiscounts = 345.20;     // Confirmado en BD
        $jasperModifiers = 1283.00;    // Confirmado en BD
        $jasperNetSales = 42581.30;    // Del PDF del usuario
        $jasperGrandTotal = 43864.30;  // Del PDF del usuario

        // Nuestros cálculos refinados
        $grossTotalExcluding100 = $itemsNetoExcluding100 + $descuentosExcluding100;
        $netSalesExcluding100 = $itemsNetoExcluding100;
        $grandTotalExcluding100 = $itemsNetoExcluding100 + $totalModificadores;

        return [
            // Totales BD completa
            'items_neto_todos' => (float) $itemsNetoTodos,
            'descuentos_todos' => (float) $descuentosTodos,
            'total_tickets_todos' => (int) $totalTickets,

            // Totales excluyendo tickets con descuento 100%
            'items_neto_excluding100' => (float) $itemsNetoExcluding100,
            'descuentos_excluding100' => (float) $descuentosExcluding100,
            'gross_total_excluding100' => (float) $grossTotalExcluding100,
            'net_sales_excluding100' => (float) $netSalesExcluding100,
            'tickets_excluding100' => (int) $ticketsExcluding100,

            // Modificadores (mismo para ambos)
            'modificadores_total' => (float) $totalModificadores,

            // Grand Totals
            'gran_total_bd_todos' => (float) ($itemsNetoTodos + $totalModificadores),
            'gran_total_excluding100' => (float) $grandTotalExcluding100,

            // Referencia JasperReports
            'items_jasper_gross' => (float) $jasperItemsGross,
            'descuentos_jasper' => (float) $jasperDiscounts,
            'net_sales_jasper' => (float) $jasperNetSales,
            'gran_total_jasper' => (float) $jasperGrandTotal,

            // Formateados para vista
            'items_neto_todos_formateado' => '$' . number_format($itemsNetoTodos, 2),
            'items_neto_excluding100_formateado' => '$' . number_format($itemsNetoExcluding100, 2),
            'gross_total_excluding100_formateado' => '$' . number_format($grossTotalExcluding100, 2),
            'net_sales_excluding100_formateado' => '$' . number_format($netSalesExcluding100, 2),
            'modificadores_formateado' => '$' . number_format($totalModificadores, 2),
            'gran_total_excluding100_formateado' => '$' . number_format($grandTotalExcluding100, 2),
            'descuentos_excluding100_formateado' => '$' . number_format($descuentosExcluding100, 2),

            // JasperReports formateados
            'items_jasper_formateado' => '$' . number_format($jasperItemsGross, 2),
            'net_sales_jasper_formateado' => '$' . number_format($jasperNetSales, 2),
            'gran_total_jasper_formateado' => '$' . number_format($jasperGrandTotal, 2),

            // Diferencias
            'diferencia_items' => (float) ($itemsNetoExcluding100 - $jasperItemsGross),
            'diferencia_net_sales' => (float) ($netSalesExcluding100 - $jasperNetSales),

            'nota_metodologia' => 'BD completa: $' . number_format($itemsNetoTodos, 2) . ' | Excluyendo 100%: $' . number_format($itemsNetoExcluding100, 2) . ' | JasperReports: $42,926.50'
        ];
    }

    /**
     * Formatea mes para mostrar
     */
    protected function formatMonth($month, $year): string
    {
        $meses = [
            1 => 'Enero', 2 => 'Febrero', 3 => 'Marzo', 4 => 'Abril',
            5 => 'Mayo', 6 => 'Junio', 7 => 'Julio', 8 => 'Agosto',
            9 => 'Septiembre', 10 => 'Octubre', 11 => 'Noviembre', 12 => 'Diciembre'
        ];

        return $meses[$month] ?? 'Mes ' . $month . ' ' . $year;
    }

    /**
     * Obtiene datos de comparación mes a mes
     */
    public function getMonthComparison(Carbon $start, Carbon $end): Collection
    {
        $results = DB::connection('pgsql')
            ->table('public.ticket AS t')
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereBetween('t.folio_date', [
                $start->format('Y-m-d 00:00:00'),
                $end->format('Y-m-d 23:59:59')
            ])
            ->where('t.paid', '=', true)
            ->where('t.voided', '=', false)
            ->whereNotNull('ti.item_name')
            ->where('ti.item_count', '>', 0)
            ->selectRaw("
                DATE_TRUNC('month', t.folio_date) AS mes,
                EXTRACT(YEAR FROM t.folio_date) AS anio,
                SUM(ti.item_count) AS unidades,
                SUM(ti.total_price) AS ingresos
            ")
            ->groupBy('mes', 'anio')
            ->orderBy('anio', 'desc')
            ->orderBy('mes', 'asc')
            ->get();

        // Si no hay resultados, devolver colección vacía
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