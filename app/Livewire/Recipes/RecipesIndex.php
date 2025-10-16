<?php

namespace App\Livewire\Recipes;

use Livewire\Component;

class RecipesIndex extends Component
{
    public function render()
    {
        return view('livewire.recipes.recipes-index')
            ->layout('layouts.terrena', ['active' => 'recetas']);
    }
}
