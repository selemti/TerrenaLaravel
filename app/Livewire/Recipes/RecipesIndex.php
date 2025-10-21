<?php

namespace App\Livewire\Recipes;

use App\Models\Rec\Receta;
use Illuminate\Database\Eloquent\Builder;
use Livewire\Component;
use Livewire\WithPagination;

class RecipesIndex extends Component
{
    use WithPagination;

    public string $search = '';
    public bool $confirmingDelete = false;
    public ?string $deleteId = null;
    public string $category = '';
    protected int $perPage = 15;

    protected $queryString = [
        'search' => ['except' => ''],
        'category' => ['except' => ''],
    ];

    public function updatingSearch(): void
    {
        $this->resetPage();
    }

    public function updatedCategory(): void
    {
        $this->resetPage();
    }

    public function confirmDelete(string $id): void
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
        if (!$this->deleteId) {
            return;
        }

        Receta::whereKey($this->deleteId)->delete();
        session()->flash('ok', 'Receta eliminada.');

        $this->cancelDelete();
        $this->resetPage();
    }

    public function render()
    {
        $recipes = Receta::query()
            ->with(['publishedVersion', 'latestVersion'])
            ->when($this->search !== '', function (Builder $query) {
                $needle = '%' . mb_strtolower($this->search) . '%';
                $query->where(function (Builder $inner) use ($needle) {
                    $inner->whereRaw('LOWER(nombre_plato) LIKE ?', [$needle])
                          ->orWhereRaw('LOWER(codigo_plato_pos) LIKE ?', [$needle]);
                });
            })
            ->when($this->category !== '', function (Builder $query) {
                if ($this->category === '__NULL__') {
                    $query->whereNull('categoria_plato');
                } else {
                    $query->where('categoria_plato', $this->category);
                }
            })
            ->orderBy('nombre_plato')
            ->paginate($this->perPage);

        $categories = Receta::query()
            ->selectRaw('COALESCE(categoria_plato, \'\') AS categoria')
            ->distinct()
            ->orderBy('categoria')
            ->get()
            ->map(fn ($row) => [
                'value' => $row['categoria'] === '' ? '__NULL__' : $row['categoria'],
                'label' => $row['categoria'] === '' ? 'Sin categoría' : $row['categoria'],
            ]);

        return view('livewire.recipes.recipes-index', [
            'recipes' => $recipes,
            'categories' => $categories,
        ])->layout('layouts.terrena', ['active' => 'recetas']);
    }
}
