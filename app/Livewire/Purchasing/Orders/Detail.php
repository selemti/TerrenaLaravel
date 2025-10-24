<?php

namespace App\Livewire\Purchasing\Orders;

use App\Models\PurchaseOrder;
use Livewire\Component;

class Detail extends Component
{
    public PurchaseOrder $order;

    public function mount($id)
    {
        $this->order = PurchaseOrder::with([
            'lines.item',
            'vendor',
            'vendorQuote',
            'creadoPor',
            'aprobadoPor',
            'sucursal'
        ])->findOrFail($id);
    }

    public function render()
    {
        return view('livewire.purchasing.orders.detail');
    }
}
