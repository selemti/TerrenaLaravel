<?php

namespace App\Http\Requests\Api\Cash;

use Illuminate\Foundation\Http\FormRequest;

class CloseCashFundRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool) $this->user()?->can('cashfund.manage');
    }

    public function rules(): array
    {
        return [
            'fecha_cierre' => ['nullable', 'date'],
            'efectivo_contado' => ['required', 'numeric', 'min:0'],
            'diferencia' => ['nullable', 'numeric'],
            'observaciones' => ['nullable', 'string'],
        ];
    }
}
