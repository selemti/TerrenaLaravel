<?php

namespace App\Livewire\Recipes;

use Livewire\Component;

class PresentacionesIndex extends Component
{
    public function render()
    {
        return view('livewire.recipes.presentaciones-index')
            ->layout('layouts.terrena', ['active' => 'recetas']);
    }
}
