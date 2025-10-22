<?php

namespace Tests\Feature\Livewire;

use App\Livewire\Inventory\ItemPriceCreate;
use Illuminate\Support\Facades\Auth;
use Tests\TestCase;

class ItemPriceCreateTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Auth::logout();
    }

    public function test_guest_mount_does_not_throw_and_flags_as_unauthorized(): void
    {
        $component = app(ItemPriceCreate::class);

        $component->mount();

        $this->assertFalse($component->authorized);
        $this->assertFalse($component->open);
    }
}
