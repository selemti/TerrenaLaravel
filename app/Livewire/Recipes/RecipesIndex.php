<?php

namespace App\Livewire\Recipes;

use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Livewire\Component;
use Livewire\WithPagination;

class RecipesIndex extends Component
{
    use WithPagination;

    public string $search = '';
    public bool $confirmingDelete = false;
    public $deleteId = null;
    public array $demoStore = [];
    public bool $usingDemoData = false;
    public bool $recipesTableReady = false;
    protected int $perPage = 10;

    protected $queryString = [
        'search' => ['except' => ''],
    ];

    public function mount(): void
    {
        $this->recipesTableReady = Schema::hasTable('recipes');

        if (! $this->recipesTableReady) {
            $this->usingDemoData = true;
            $this->demoStore = $this->defaultRecipes()
                ->map(fn ($row) => $row)
                ->all();
        }
    }

    public function updatingSearch(): void
    {
        $this->resetPage();
    }

    public function confirmDelete($id): void
    {
        $this->deleteId = $id;
        $this->confirmingDelete = true;
    }

    public function cancelDelete(): void
    {
        $this->confirmingDelete = false;
        $this->deleteId = null;
    }

    public function delete(): void
    {
        if (is_null($this->deleteId)) {
            return;
        }

        if ($this->recipesTableReady) {
            DB::table('recipes')->where('id', $this->deleteId)->delete();
            session()->flash('ok', 'Receta eliminada.');
        } else {
            $this->demoStore = collect($this->demoStore)
                ->reject(fn ($row) => (string)($row['id'] ?? '') === (string) $this->deleteId)
                ->values()
                ->all();
            session()->flash('ok', 'Receta eliminada (datos de demostración).');
        }

        $this->cancelDelete();
        $this->resetPage();
    }

    public function render()
    {
        $recipes = $this->recipesTableReady
            ? $this->paginateFromDatabase()
            : $this->paginateFromDemo();

        return view('livewire.recipes.recipes-index', [
            'recipes'       => $recipes,
            'usingDemoData' => $this->usingDemoData && ! $this->recipesTableReady,
        ])->layout('layouts.terrena', ['active' => 'recetas']);
    }

    protected function paginateFromDatabase(): LengthAwarePaginator
    {
        $query = DB::table('recipes');

        $hasCodigo = Schema::hasColumn('recipes', 'codigo');
        $hasNombre = Schema::hasColumn('recipes', 'nombre');
        $hasRend = Schema::hasColumn('recipes', 'rendimiento');
        $hasUnidad = Schema::hasColumn('recipes', 'unidad');
        $hasCosto = Schema::hasColumn('recipes', 'costo');

        if ($this->search !== '' && $hasNombre) {
            $needle = '%' . mb_strtolower($this->search) . '%';
            $query->whereRaw('LOWER(nombre) LIKE ?', [$needle]);
        } elseif ($this->search !== '' && $hasCodigo) {
            $needle = '%' . mb_strtolower($this->search) . '%';
            $query->whereRaw('LOWER(codigo) LIKE ?', [$needle]);
        }

        $page = $this->getPage();
        $total = (clone $query)->count();
        $items = $query->orderBy($hasNombre ? 'nombre' : 'id')
            ->forPage($page, $this->perPage)
            ->get()
            ->map(function ($row) use ($hasCodigo, $hasNombre, $hasRend, $hasUnidad, $hasCosto) {
                $row->codigo = $hasCodigo ? ($row->codigo ?? null) : null;
                $row->nombre = $hasNombre ? ($row->nombre ?? 'Receta') : 'Receta';
                $row->rendimiento = $hasRend ? ($row->rendimiento ?? 1) : 1;
                $row->unidad = $hasUnidad ? ($row->unidad ?? 'pz') : 'pz';
                $row->costo = $hasCosto ? ($row->costo ?? 0) : 0;
                return $row;
            });

        return new LengthAwarePaginator($items, $total, $this->perPage, $page, [
            'path'  => request()->url(),
            'query' => request()->query(),
        ]);
    }

    protected function paginateFromDemo(): LengthAwarePaginator
    {
        $collection = collect($this->demoStore);

        if ($this->search !== '') {
            $needle = mb_strtolower($this->search);
            $collection = $collection->filter(function ($row) use ($needle) {
                return str_contains(mb_strtolower($row['nombre']), $needle)
                    || str_contains(mb_strtolower((string) ($row['codigo'] ?? '')), $needle);
            });
        }

        $total = $collection->count();
        $page = $this->getPage();

        $items = $collection
            ->slice(($page - 1) * $this->perPage, $this->perPage)
            ->values()
            ->map(fn ($row) => (object) $row);

        return new LengthAwarePaginator($items, $total, $this->perPage, $page, [
            'path'  => request()->url(),
            'query' => request()->query(),
        ]);
    }

    protected function defaultRecipes(): Collection
    {
        return collect([
            [
                'id'         => 1,
                'codigo'     => 'REC-001',
                'nombre'     => 'Torta de pollo clásica',
                'rendimiento'=> 1.0,
                'unidad'     => 'pz',
                'costo'      => 28.5,
            ],
            [
                'id'         => 2,
                'codigo'     => 'REC-002',
                'nombre'     => 'Sopa de tomate (1L)',
                'rendimiento'=> 1.0,
                'unidad'     => 'L',
                'costo'      => 18.2,
            ],
            [
                'id'         => 3,
                'codigo'     => 'REC-003',
                'nombre'     => 'Aderezo de la casa',
                'rendimiento'=> 0.75,
                'unidad'     => 'L',
                'costo'      => 9.4,
            ],
            [
                'id'         => 4,
                'codigo'     => 'REC-004',
                'nombre'     => 'Brownie individual',
                'rendimiento'=> 1.0,
                'unidad'     => 'pz',
                'costo'      => 12.9,
            ],
        ]);
    }
}
