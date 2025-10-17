<?php

namespace App\Http\Requests\Caja;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePostcorteRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // TODO: Add proper authorization logic based on user role (supervisor/manager only)
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
            'veredicto_efectivo' => 'nullable|in:CUADRA,A_FAVOR,EN_CONTRA',
            'veredicto_tarjetas' => 'nullable|in:CUADRA,A_FAVOR,EN_CONTRA',
            'veredicto_transferencias' => 'nullable|in:CUADRA,A_FAVOR,EN_CONTRA',
            'notas' => 'nullable|string|max:1000',
            'validado' => 'nullable|boolean',
            'sesion_estatus' => 'nullable|in:CERRADA,CONCILIADA',
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
            'veredicto_efectivo.in' => 'El veredicto de efectivo debe ser CUADRA, A_FAVOR o EN_CONTRA.',
            'veredicto_tarjetas.in' => 'El veredicto de tarjetas debe ser CUADRA, A_FAVOR o EN_CONTRA.',
            'veredicto_transferencias.in' => 'El veredicto de transferencias debe ser CUADRA, A_FAVOR o EN_CONTRA.',
            'notas.max' => 'Las notas no pueden exceder 1000 caracteres.',
            'validado.boolean' => 'El campo validado debe ser verdadero o falso.',
            'sesion_estatus.in' => 'El estatus de sesión debe ser CERRADA o CONCILIADA.',
        ];
    }
}
