<?php

namespace App\Http\Requests\Api\Cash;

use Illuminate\Foundation\Http\FormRequest;

class RegisterCashFundMovementRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool) $this->user()?->can('cashfund.manage');
    }

    public function rules(): array
    {
        return [
            'fecha_hora' => ['nullable', 'date'],
            'tipo' => ['required', 'string', 'max:20'],
            'concepto' => ['required', 'string'],
            'proveedor_id' => ['nullable', 'integer'],
            'monto' => ['required', 'numeric', 'min:0.01'],
            'metodo' => ['nullable', 'string', 'max:20'],
            'requiere_comprobante' => ['sometimes', 'boolean'],
            'estatus' => ['nullable', 'string', 'max:24'],
            'meta' => ['nullable', 'array'],
            'attachments' => ['nullable', 'array'],
            'attachments.*.tipo' => ['nullable', 'string', 'max:20'],
            'attachments.*.archivo_url' => ['required_with:attachments', 'string'],
            'attachments.*.observaciones' => ['nullable', 'string'],
        ];
    }
}
