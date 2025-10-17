<?php

namespace App\Http\Requests\Caja;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePrecorteRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // TODO: Add proper authorization logic based on user role
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'denoms_json' => 'required|json',
            'declarado_credito' => 'required|numeric|min:0',
            'declarado_debito' => 'required|numeric|min:0',
            'declarado_transfer' => 'required|numeric|min:0',
            'notas' => 'nullable|string|max:500',
        ];
    }

    /**
     * Get custom messages for validator errors.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'denoms_json.required' => 'Las denominaciones de efectivo son requeridas.',
            'denoms_json.json' => 'Las denominaciones deben estar en formato JSON válido.',
            'declarado_credito.required' => 'El monto de tarjeta de crédito es requerido.',
            'declarado_credito.numeric' => 'El monto de tarjeta de crédito debe ser un número.',
            'declarado_credito.min' => 'El monto de tarjeta de crédito no puede ser negativo.',
            'declarado_debito.required' => 'El monto de tarjeta de débito es requerido.',
            'declarado_debito.numeric' => 'El monto de tarjeta de débito debe ser un número.',
            'declarado_debito.min' => 'El monto de tarjeta de débito no puede ser negativo.',
            'declarado_transfer.required' => 'El monto de transferencias es requerido.',
            'declarado_transfer.numeric' => 'El monto de transferencias debe ser un número.',
            'declarado_transfer.min' => 'El monto de transferencias no puede ser negativo.',
            'notas.max' => 'Las notas no pueden exceder 500 caracteres.',
        ];
    }
}
