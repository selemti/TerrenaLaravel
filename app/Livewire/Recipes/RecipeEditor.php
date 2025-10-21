<?php

namespace App\Livewire\Recipes;

use Livewire\Component;

class RecipeEditor extends Component
{
    public ?string $id = null;

    public function render()
    {
        return view('livewire.recipes.recipe-editor')
            ->layout('layouts.terrena', ['active' => 'recetas']);
    }
}
