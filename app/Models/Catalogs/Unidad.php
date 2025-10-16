<?php

namespace App\Models\Catalogs;

use Illuminate\Database\Eloquent\Model;

class Unidad extends Model
{
    // OJO: estamos yendo directo a la tabla del esquema selemti
    protected $table = 'selemti.unidades_medida';
    protected $primaryKey = 'id';
    public $timestamps = false; // la tabla tiene created_at pero no updated_at

    protected $fillable = [
        'codigo',                 // VARCHAR(10) UNIQUE NOT NULL
        'nombre',                 // VARCHAR(50) NOT NULL
        'tipo',                   // 'PESO'|'VOLUMEN'|'UNIDAD'|'TIEMPO'
        'categoria',              // 'METRICO'|'IMPERIAL'|'CULINARIO'|NULL
        'es_base',                // boolean
        'factor_conversion_base', // numeric(12,6)
        'decimales',              // int
    ];

    protected $casts = [
        'es_base' => 'boolean',
        'factor_conversion_base' => 'decimal:6',
        'decimales' => 'integer',
    ];
}
