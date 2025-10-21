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
     * Prepare the data for validation.
     * Merge query parameters with request data for validation
     */
    protected function prepareForValidation(): void
    {
        // Merge query parameters (like ?precorte_id=27) with body data
        $this->merge([
            'precorte_id' => $this->input('precorte_id') ?? $this->query('precorte_id'),
        ]);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            // Nota: selemti.precorte se refiere al esquema.tabla en PostgreSQL
            'precorte_id' => 'required|integer',
            'notas' => 'nullable|string|max:1000',
        ];
    }

    /**
     * Configure the validator instance.
     */
    public function withValidator($validator)
    {
        $validator->after(function ($validator) {
            if ($this->precorte_id) {
                // Validar manualmente que el precorte existe en PostgreSQL
                $exists = \DB::connection('pgsql')
                    ->table('selemti.precorte')
                    ->where('id', $this->precorte_id)
                    ->exists();

                if (!$exists) {
                    $validator->errors()->add('precorte_id', 'El precorte especificado no existe.');
                }
            }
        });
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
