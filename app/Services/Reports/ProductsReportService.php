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
                $end->format('Y-m-d 23:59:59'),
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
                $row->ingreso_total_formateado = '$'.number_format($row->ingreso_total, 2);

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
            ->selectRaw('
                ti.category_name AS categoria,
                COUNT(DISTINCT t.id) AS tickets_totales,
                SUM(ti.item_count) AS unidades_vendidas,
                SUM(ti.total_price) AS ingreso_total,
                ROUND(SUM(ti.total_price)::numeric, 2) AS ingreso_total_redondeado,
                AVG(ti.item_price) AS precio_promedio,
                COUNT(DISTINCT ti.item_name) AS productos_unicos
            ')
            ->groupBy('ti.category_name')
            ->orderBy('ingreso_total', 'desc')
            ->get();

        return $results->map(function ($row) {
            $row->ingreso_total_formateado = '$'.number_format($row->ingreso_total, 2);
            $row->precio_promedio_formateado = '$'.number_format($row->precio_promedio, 2);

            return $row;
        });
    }

    /**
     * Agrupa datos por producto
     */
    protected function groupByProduct($query): Collection
    {
        return $query
            ->selectRaw('
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
            ')
            ->groupBy('ti.category_name', 'ti.group_name', 'ti.item_name')
            ->orderBy('ingreso_total', 'desc')
            ->get()
            ->map(function ($row) {
                $row->ingreso_total_formateado = '$'.number_format($row->ingreso_total, 2);
                $row->precio_promedio_formateado = '$'.number_format($row->precio_promedio, 2);
                $row->precio_minimo_formateado = '$'.number_format($row->precio_minimo, 2);
                $row->precio_maximo_formateado = '$'.number_format($row->precio_maximo, 2);

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
                $end->format('Y-m-d'),
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

        $query = DB::connection('pgsql')
            ->table('public.ticket AS t')
            ->whereBetween('t.folio_date', [
                $start->format('Y-m-d 00:00:00'),
                $end->format('Y-m-d 23:59:59'),
            ])
            ->where('t.paid', '=', true)
            ->where('t.voided', '=', false);

        if ($branchIds && count($branchIds) > 0) {
            $query->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds && count($terminalIds) > 0) {
            $query->whereIn('t.terminal_id', $terminalIds);
        }

        // 1. Metodología Canon (SSOT via Transactions)
        $canonTotals = DB::connection('pgsql')
            ->table('public.transactions as tx')
            ->join('public.ticket as t', 't.id', '=', 'tx.ticket_id')
            ->whereBetween('t.folio_date', [
                $start->format('Y-m-d 00:00:00'),
                $end->format('Y-m-d 23:59:59'),
            ])
            ->where(function ($q) {
                $q->where('tx.voided', false)->orWhereNull('tx.voided');
            })
            ->whereIn(DB::raw('UPPER(COALESCE(tx.transaction_type, \'\'))'), ['CREDIT', 'DEBIT'])
            ->whereNotIn(DB::raw('UPPER(COALESCE(tx.payment_type, \'\'))'), ['REFUND', 'VOID_TRANS', 'REFUND_CARD'])
            ->where('tx.amount', '>', 0)
            ->selectRaw('SUM(tx.amount) as canon_neto, COUNT(DISTINCT t.id) as canon_tickets')
            ->first();

        // 2. Metodología Legacy (ticket_item sum)
        $menuItemsTotals = (clone $query)
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereNotNull('ti.item_name')
            ->selectRaw('
                SUM(ti.total_price) as items_neto,
                SUM(CASE WHEN ti.discount > 0 THEN ti.discount ELSE 0 END) as descuentos_items,
                COUNT(DISTINCT t.id) as total_tickets
            ')
            ->first();

        // 3. Metodología JasperReports (Excluyendo 100%) - PARCHE DETECTADO
        $menuItemsExcluding100 = (clone $query)
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereNotNull('ti.item_name')
            ->where('t.total_price', '>', 0)
            ->selectRaw('
                SUM(ti.total_price) as items_neto_excluding_100,
                SUM(CASE WHEN ti.discount > 0 THEN ti.discount ELSE 0 END) as descuentos_excluding_100,
                COUNT(DISTINCT t.id) as tickets_excluding_100
            ')
            ->first();

        $totalModificadores = (clone $query)
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->join('public.ticket_item_modifier AS tim', 'tim.ticket_item_id', '=', 'ti.id')
            ->sum(DB::raw('COALESCE(tim.total_price, 0)'));

        $res = [
            'is_canon_mode' => $isCanon,
            'items_neto_todos' => (float) ($menuItemsTotals->items_neto ?? 0),
            'descuentos_todos' => (float) ($menuItemsTotals->descuentos_items ?? 0),
            'total_tickets_todos' => (int) ($menuItemsTotals->total_tickets ?? 0),

            'items_neto_excluding100' => (float) ($menuItemsExcluding100->items_neto_excluding_100 ?? 0),
            'descuentos_excluding100' => (float) ($menuItemsExcluding100->descuentos_excluding_100 ?? 0),
            'tickets_excluding100' => (int) ($menuItemsExcluding100->tickets_excluding_100 ?? 0),

            'modificadores_total' => (float) $totalModificadores,
            'canon_neto' => (float) ($canonTotals->canon_neto ?? 0),
            'canon_tickets' => (int) ($canonTotals->canon_tickets ?? 0),
        ];

        // Resolviendo "Net Sales" dinámicos
        $res['net_sales_current'] = $isCanon ? $res['canon_neto'] : $res['items_neto_todos'];
        $res['gran_total_current'] = $res['net_sales_current'] + $res['modificadores_total'];

        // Mantener compatibilidad con keys previos para la vista
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
        $results = DB::connection('pgsql')
            ->table('public.ticket AS t')
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->whereBetween('t.folio_date', [
                $start->format('Y-m-d 00:00:00'),
                $end->format('Y-m-d 23:59:59'),
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
