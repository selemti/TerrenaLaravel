<?php

namespace App\Http\Requests\Api\Cash;

use Illuminate\Foundation\Http\FormRequest;

class OpenCashFundRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool) $this->user()?->can('cashfund.manage');
    }

    public function rules(): array
    {
        return [
            'sucursal_id' => ['required', 'integer'],
            'fecha' => ['nullable', 'date'],
            'monto_inicial' => ['required', 'numeric', 'min:0.01'],
            'moneda' => ['nullable', 'string', 'max:10'],
            'meta' => ['nullable', 'array'],
            'usuarios' => ['nullable', 'array'],
            'usuarios.*.user_id' => ['required', 'integer'],
            'usuarios.*.rol' => ['nullable', 'string', 'max:20'],
        ];
    }
}
