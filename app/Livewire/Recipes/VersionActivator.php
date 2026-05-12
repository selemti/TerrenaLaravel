<?php

namespace App\Livewire\Recipes;

use App\Services\Recetas\RecipeVersionService;
use Illuminate\Support\Collection;
use Livewire\Component;

class VersionActivator extends Component
{
    public string $recipeId = '';

    public array $versions = [];

    public ?int $selectedVersion = null;

    public ?string $statusMessage = null;

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

    public function loadVersions(RecipeVersionService $service): void
    {
        $this->errorMessage = null;
        $this->statusMessage = null;
        $this->versions = [];
        $this->selectedVersion = null;

        if ($this->recipeId === '') {
            return;
        }

        $this->loading = true;

        try {
            $history = $service->getVersionHistory($this->recipeId);
            $this->versions = $this->mapVersions($history);
            $this->selectedVersion = collect($this->versions)
                ->firstWhere('publicada', false)['id']
                ?? $this->versions[0]['id']
                ?? null;
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        } finally {
            $this->loading = false;
        }
    }

    public function publish(RecipeVersionService $service): void
    {
        $this->errorMessage = null;
        $this->statusMessage = null;

        if (! $this->selectedVersion) {
            $this->errorMessage = 'Selecciona una versión para publicar.';

            return;
        }

        $this->loading = true;

        try {
            $userId = auth()->id() ?? 1;
            $published = $service->publishVersion((int) $this->selectedVersion, (int) $userId);
            $this->statusMessage = "Versión v{$published->version} publicada.";

            $this->dispatch('version-published', versionId: $published->id);
            $this->loadVersions($service);
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        } finally {
            $this->loading = false;
        }
    }

    protected function mapVersions(Collection $versions): array
    {
        return $versions->map(function ($version) {
            return [
                'id' => $version->id,
                'version' => $version->version,
                'descripcion_cambios' => $version->descripcion_cambios,
                'publicada' => (bool) $version->version_publicada,
            ];
        })->sortByDesc('version')->values()->all();
    }

    public function render()
    {
        return view('livewire.recipes.version-activator');
    }
}
