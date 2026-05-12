<?php

namespace App\Livewire\Recipes;

use App\Services\Recetas\RecipeVersionService;
use Illuminate\Support\Collection;
use Livewire\Attributes\On;
use Livewire\Component;

class VersionComparator extends Component
{
    public string $recipeId = '';

    public array $versions = [];

    public ?int $leftVersionId = null;

    public ?int $rightVersionId = null;

    public array $comparison = [];

    public ?string $errorMessage = null;

    public bool $loading = false;

    public function mount(?string $recipeId, RecipeVersionService $service): void
    {
        $this->recipeId = $recipeId ? strtoupper($recipeId) : '';

        if ($this->recipeId !== '') {
            $this->loadVersions($service);
        }
    }

    public function updatedRecipeId(RecipeVersionService $service): void
    {
        $this->recipeId = strtoupper($this->recipeId);
        $this->loadVersions($service);
    }

    public function updatedLeftVersionId(RecipeVersionService $service): void
    {
        $this->compare($service);
    }

    public function updatedRightVersionId(RecipeVersionService $service): void
    {
        $this->compare($service);
    }

    public function loadVersions(RecipeVersionService $service): void
    {
        $this->resetComparison();
        $this->versions = [];

        if ($this->recipeId === '') {
            return;
        }

        $this->loading = true;
        $this->errorMessage = null;

        try {
            $history = $service->getVersionHistory($this->recipeId);
            $this->versions = $this->mapVersions($history);
            $this->selectDefaults();
            $this->compare($service);
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        } finally {
            $this->loading = false;
        }
    }

    #[On('version-published')]
    public function handleVersionPublished(int $versionId, RecipeVersionService $service): void
    {
        $this->loadVersions($service);

        if ($versionId > 0) {
            $this->leftVersionId = $versionId;
        }
    }

    public function compare(RecipeVersionService $service): void
    {
        $this->comparison = [];
        $this->errorMessage = null;

        if (! $this->leftVersionId || ! $this->rightVersionId) {
            return;
        }

        try {
            $this->comparison = $service->compareVersions($this->leftVersionId, $this->rightVersionId);
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }
    }

    protected function mapVersions(Collection $versions): array
    {
        return $versions->map(function ($version) {
            return [
                'id' => $version->id,
                'version' => $version->version,
                'descripcion_cambios' => $version->descripcion_cambios,
                'fecha_efectiva' => optional($version->fecha_efectiva)->toDateString() ?? $version->fecha_efectiva,
                'publicada' => (bool) $version->version_publicada,
                'total_ingredientes' => $version->detalles?->count() ?? 0,
            ];
        })->sortByDesc('version')->values()->all();
    }

    protected function selectDefaults(): void
    {
        if (empty($this->versions)) {
            $this->leftVersionId = null;
            $this->rightVersionId = null;

            return;
        }

        $collection = collect($this->versions);
        $published = $collection->firstWhere('publicada', true);
        $latest = $collection->sortByDesc('version')->first();
        $secondLatest = $collection->sortByDesc('version')->skip(1)->first();

        $this->leftVersionId = $published['id'] ?? $latest['id'] ?? null;
        $this->rightVersionId = $latest && $latest['id'] !== $this->leftVersionId
            ? $latest['id']
            : ($secondLatest['id'] ?? null);
    }

    protected function resetComparison(): void
    {
        $this->comparison = [];
        $this->errorMessage = null;
    }

    public function render()
    {
        return view('livewire.recipes.version-comparator')
            ->layout('layouts.terrena', [
                'active' => 'recetas',
                'title' => 'Versionado de recetas',
                'pageTitle' => 'Versionado de recetas',
            ]);
    }
}
