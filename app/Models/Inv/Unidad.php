<?php

namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class Unidad extends Model
{
    // Si tienes DB_SCHEMA=selemti,public en .env NO hace falta prefijar el esquema.
    protected $table = 'unidades_medida'; // Asume que DB_SCHEMA está configurado
    protected $primaryKey = 'id';
    public $timestamps = false; // No hay updated_at

    protected $fillable = [
        'codigo','nombre','tipo','categoria',
        'es_base','factor_conversion_base','decimales','created_at',
    ];

    protected $casts = [
        'es_base' => 'boolean',
        'factor_conversion_base' => 'decimal:6', // Asumo 6 decimales para factor
        'decimales' => 'integer',
        'created_at' => 'datetime',
    ];
}