<?php

namespace Tests\Feature\Livewire;

use App\Livewire\Inventory\ItemPriceCreate;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Tests\TestCase;

class ItemPriceCreateTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Auth::logout();
    }

    public function test_guest_cannot_access_price_create_component(): void
    {
        $this->expectException(HttpException::class);

        app(ItemPriceCreate::class)->mount();
    }
}
