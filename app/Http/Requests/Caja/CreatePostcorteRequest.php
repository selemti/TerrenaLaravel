<?php

namespace App\Http\Requests\Caja;

use Illuminate\Foundation\Http\FormRequest;

class CreatePostcorteRequest extends FormRequest
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
            'precorte_id' => 'required|integer|exists:selemti.precorte,id',
            'notas' => 'nullable|string|max:1000',
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
            'precorte_id.required' => 'El ID del precorte es requerido.',
            'precorte_id.integer' => 'El ID del precorte debe ser un número entero.',
            'precorte_id.exists' => 'El precorte especificado no existe.',
            'notas.max' => 'Las notas no pueden exceder 1000 caracteres.',
        ];
    }
}
