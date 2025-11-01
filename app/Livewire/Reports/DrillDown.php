<?php

namespace App\Livewire\Reports;

use App\Models\Reports\ReportFavorite;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Livewire\Component;

class DrillDown extends Component
{
    public string $type;
    public ?string $identifier = null;
    public array $breadcrumbs = [];
    public array $rows = [];
    public array $filters = [];

    public function mount(string $type, ?string $id = null): void
    {
        $this->type = $type;
        $this->identifier = $id;

        $this->filters = [
            'dateRange' => 'last_30_days',
        ];

        $this->buildBreadcrumbs();
        $this->loadData();
    }

    public function updatedFiltersDateRange(): void
    {
        $this->loadData();
    }

    public function loadData(): void
    {
        $range = $this->resolveRange($this->filters['dateRange'] ?? 'last_30_days');

        $from = $range[0]->toDateTimeString();
        $to = $range[1]->toDateTimeString();

        $this->rows = match ($this->type) {
            'ventas' => $this->loadSalesDetail($from, $to),
            'inventario' => $this->loadInventoryDetail($from, $to),
            'produccion' => $this->loadProductionDetail($from, $to),
            default => [],
        };

        $this->dispatch('drilldown-data-updated', data: [
            'type' => $this->type,
            'rows' => $this->rows,
        ]);
    }

    public function markFavorite(): void
    {
        $user = auth()->user();
        if (! $user) {
            return;
        }

        $key = sprintf('drilldown_%s_%s', $this->type, $this->identifier ?: 'root');

        ReportFavorite::updateOrCreate(
            ['user_id' => $user->id, 'report_key' => $key],
            ['meta' => ['filters' => $this->filters]]
        );

        $this->dispatch('toast', type: 'success', body: 'Drill-down guardado en favoritos');
    }

    public function render()
    {
        return view('livewire.reports.drill-down')
            ->layout('layouts.terrena', [
                'active' => 'reportes',
                'title' => 'Detalle de reporte',
                'pageTitle' => 'Detalle de reporte',
            ]);
    }

    protected function buildBreadcrumbs(): void
    {
        $items = [
            ['label' => 'Dashboard', 'route' => route('reports.dashboard')],
        ];

        $typeLabel = Str::headline($this->type);
        $items[] = ['label' => $typeLabel, 'route' => route('reports.drill-down', ['type' => $this->type])];

        if ($this->identifier) {
            $items[] = ['label' => $this->identifier, 'route' => null];
        }

        $this->breadcrumbs = $items;
    }

    protected function loadSalesDetail(string $from, string $to): array
    {
        return $this->safeCollection(fn () =>
            DB::connection('pgsql')
                ->table('ticket_item')
                ->selectRaw('item_name, SUM(qty) AS cantidad, SUM(total_price) AS total')
                ->whereBetween('created_at', [$from, $to])
                ->groupBy('item_name')
                ->orderByDesc('total')
                ->limit(50)
                ->get()
                ->map(fn ($row) => [
                    'label' => $row->item_name,
                    'cantidad' => (float) $row->cantidad,
                    'total' => (float) $row->total,
                ])
                ->all()
        );
    }

    protected function loadInventoryDetail(string $from, string $to): array
    {
        return $this->safeCollection(fn () =>
            DB::connection('pgsql')
                ->table('vw_stock_valorizado')
                ->selectRaw('almacen_nombre, SUM(valor_total) AS valor_total, SUM(stock_total) AS stock_total')
                ->groupBy('almacen_nombre')
                ->orderByDesc('valor_total')
                ->get()
                ->map(fn ($row) => [
                    'label' => $row->almacen_nombre ?? 'Sin nombre',
                    'valor_total' => (float) $row->valor_total,
                    'stock_total' => (float) ($row->stock_total ?? 0),
                ])
                ->all()
        );
    }

    protected function loadProductionDetail(string $from, string $to): array
    {
        return $this->safeCollection(fn () =>
            DB::connection('pgsql')
                ->table('production_orders')
                ->selectRaw('COALESCE(folio, id::text) AS folio, qty_programada, qty_producida, qty_merma, estado')
                ->whereBetween('programado_para', [$from, $to])
                ->orderByDesc('programado_para')
                ->limit(100)
                ->get()
                ->map(fn ($row) => [
                    'label' => $row->folio,
                    'programada' => (float) $row->qty_programada,
                    'producida' => (float) $row->qty_producida,
                    'merma' => (float) $row->qty_merma,
                    'estado' => $row->estado,
                ])
                ->all()
        );
    }

    /**
     * @return array{0:Carbon,1:Carbon}
     */
    protected function resolveRange(string $range): array
    {
        $now = now();

        return match ($range) {
            'today' => [$now->copy()->startOfDay(), $now->copy()->endOfDay()],
            'yesterday' => [$now->copy()->subDay()->startOfDay(), $now->copy()->subDay()->endOfDay()],
            'last_7_days' => [$now->copy()->subDays(6)->startOfDay(), $now->copy()->endOfDay()],
            'this_month' => [$now->copy()->startOfMonth(), $now->copy()->endOfMonth()],
            'last_month' => [$now->copy()->subMonth()->startOfMonth(), $now->copy()->subMonth()->endOfMonth()],
            default => [$now->copy()->subDays(29)->startOfDay(), $now->copy()->endOfDay()],
        };
    }

    /**
     * @param  callable():array<int, mixed>  $callback
     * @return array<int, mixed>
     */
    protected function safeCollection(callable $callback): array
    {
        try {
            $result = $callback();
            return is_array($result) ? $result : [];
        } catch (\Throwable $e) {
            report($e);
            return [];
        }
    }
}
