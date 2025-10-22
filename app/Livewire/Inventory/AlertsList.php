<?php

namespace App\Livewire\Inventory;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

class AlertsList extends Component
{
    use AuthorizesRequests;
    use WithPagination;

    protected $paginationTheme = 'bootstrap';

    public string $handled = 'pending';
    public ?string $dateFrom = null;
    public ?string $dateTo = null;
    public ?string $recipeId = null;
    public int $perPage = 15;

    protected $queryString = [
        'handled' => ['except' => 'pending'],
        'dateFrom' => ['except' => null],
        'dateTo' => ['except' => null],
        'recipeId' => ['except' => null],
    ];

    public function mount(): void
    {
        abort_unless(Auth::check(), 403);
        $this->authorize('inventory.alerts.manage');
    }

    public function updatingHandled(): void
    {
        $this->resetPage();
    }

    public function updatingDateFrom(): void
    {
        $this->resetPage();
    }

    public function updatingDateTo(): void
    {
        $this->resetPage();
    }

    public function updatingRecipeId(): void
    {
        $this->resetPage();
    }

    public function acknowledge(int $alertId): void
    {
        $this->authorize('inventory.alerts.manage');

        $updated = DB::connection('pgsql')
            ->table('selemti.alert_events')
            ->where('id', $alertId)
            ->update(['handled' => true]);

        if ($updated) {
            $this->dispatch('toast', type: 'success', body: 'Alerta marcada como atendida.');
        } else {
            $this->dispatch('toast', type: 'warning', body: 'No se encontró la alerta seleccionada.');
        }

        $this->resetPage();
    }

    public function render()
    {
        $alerts = $this->buildQuery()->paginate($this->perPage);

        return view('livewire.inventory.alerts-list', [
            'alerts' => $alerts,
        ])->layout('layouts.terrena', [
            'active' => 'alerts',
            'title' => 'Alertas de costos',
            'pageTitle' => 'Alertas de costo de recetas',
        ]);
    }

    protected function buildQuery()
    {
        $query = DB::connection('pgsql')
            ->table(DB::raw('selemti.alert_events as ae'))
            ->leftJoin(DB::raw('selemti.recipes as r'), 'r.id', '=', 'ae.recipe_id')
            ->select([
                'ae.id',
                'ae.recipe_id',
                'ae.snapshot_at',
                'ae.old_portion_cost',
                'ae.new_portion_cost',
                'ae.delta_pct',
                'ae.created_at',
                'ae.handled',
                'r.nombre as recipe_name',
                'r.codigo as recipe_code',
            ])
            ->orderByDesc('ae.snapshot_at');

        if ($this->handled === 'pending') {
            $query->where('ae.handled', false);
        } elseif ($this->handled === 'handled') {
            $query->where('ae.handled', true);
        }

        if ($this->recipeId) {
            $query->where('ae.recipe_id', $this->recipeId);
        }

        if ($from = $this->parseDate($this->dateFrom, false)) {
            $query->where('ae.snapshot_at', '>=', $from);
        }

        if ($to = $this->parseDate($this->dateTo, true)) {
            $query->where('ae.snapshot_at', '<=', $to);
        }

        return $query;
    }

    private function parseDate(?string $value, bool $endOfDay): ?string
    {
        if (! $value) {
            return null;
        }

        try {
            $date = Carbon::parse($value);
        } catch (\Exception $exception) {
            return null;
        }

        return $endOfDay
            ? $date->endOfDay()->toDateTimeString()
            : $date->startOfDay()->toDateTimeString();
    }
}
