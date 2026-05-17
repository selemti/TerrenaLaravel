<?php

namespace App\Livewire\Kds;

use Livewire\Component;

class Board extends Component
{
    public bool $hasAccess = false;

    public function mount(): void
    {
        $this->hasAccess = auth()->check() && (
            auth()->user()->hasPermissionTo('kitchen.view_kds') ||
            auth()->user()->hasPermissionTo('can_edit_production_order')
        );
    }

    public function render()
    {
        return view('livewire.kds.board')
            ->layout('layouts.terrena', [
                'active' => 'kds',
                'title' => 'KDS · Cocina',
            ]);
    }
}
