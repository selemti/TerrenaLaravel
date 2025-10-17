<?php

namespace App\Http\Requests\Catalogs;

use Illuminate\Foundation\Http\FormRequest;

class StoreUnidadRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // aplicar policies/permissions en rutas/controlador
    }

    public function rules(): array
    {
        return [
            'codigo' => ['required','alpha_dash','max:10','unique:selemti.unidades_medida,codigo'],
            'nombre' => ['required','string','max:50'],
            'tipo'   => ['required','in:PESO,VOLUMEN,UNIDAD,TIEMPO'],
            'categoria' => ['nullable','in:METRICO,IMPERIAL,CULINARIO'],
            'es_base' => ['nullable','boolean'],
            'factor_conversion_base' => ['nullable','numeric','min:0'],
            'decimales' => ['nullable','integer','between:0,6'],
        ];
    }

    public function attributes(): array
    {
        return [
            'codigo' => 'código',
            'nombre' => 'nombre',
            'tipo' => 'tipo',
            'categoria' => 'categoría',
            'es_base' => 'es base',
            'factor_conversion_base' => 'factor conversión base',
            'decimales' => 'decimales',
        ];
    }
}

