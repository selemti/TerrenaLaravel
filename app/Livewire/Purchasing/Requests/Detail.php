<?php

namespace App\Livewire\Purchasing\Requests;

use App\Models\PurchaseRequest;
use Livewire\Component;

class Detail extends Component
{
    public PurchaseRequest $request;

    public function mount($id)
    {
        $this->request = PurchaseRequest::with([
            'lines.item',
            'lines.preferredVendor',
            'quotes.vendor',
            'createdBy',
            'requestedBy',
            'sucursal'
        ])->findOrFail($id);
    }

    public function render()
    {
        return view('livewire.purchasing.requests.detail');
    }
}
