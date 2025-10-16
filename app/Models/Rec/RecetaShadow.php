<?php

namespace App\Models\Rec;

use Illuminate\Database\Eloquent\Model;

class RecetaShadow extends Model
{
    protected $table = 'selemti.receta_shadow';
    protected $primaryKey = 'id';
    public $timestamps = true;

    protected $fillable = [
        'codigo_plato_pos', 'nombre_plato', 'estado', 'confianza', 
        'total_ventas_analizadas', 'fecha_primer_venta', 'fecha_ultima_venta', 
        'frecuencia_dias', 'ingredientes_inferidos', 'usuario_validador', 
        'fecha_validacion'
    ];

    protected $casts = [
        'confianza' => 'decimal:4',
        'fecha_primer_venta' => 'date',
        'fecha_ultima_venta' => 'date',
        'ingredientes_inferidos' => 'json',
        'fecha_validacion' => 'datetime',
    ];
}