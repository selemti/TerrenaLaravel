<?php

namespace App\Http\Requests\Api\Inventory;

use App\Support\Inventory\VendorPriceValidation;
use Illuminate\Foundation\Http\FormRequest;

class StoreVendorPriceRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();

        return $user !== null && $user->can('inventory.prices.manage');
    }

    public function rules(): array
    {
        return VendorPriceValidation::rules();
    }

    protected function prepareForValidation(): void
    {
        $this->replace(VendorPriceValidation::sanitize($this->all()));
    }

    public function withValidator($validator)
    {
        $validator->after(function ($validator) {
            VendorPriceValidation::afterValidation($validator, $this->all());
        });
    }
}
