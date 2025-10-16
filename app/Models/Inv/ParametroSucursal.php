<?php

namespace App\Models\Inv;

use Illuminate\Database\Eloquent\Model;

class ParametroSucursal extends Model
{
    protected $table = 'selemti.param_sucursal';
    protected $primaryKey = 'id';
    public $timestamps = true;

    protected $fillable = [
        'sucursal_id', 'consumo', 'tolerancia_precorte_pct', 
        'tolerancia_corte_abs', 'created_at', 'updated_at'
    ];

    protected $casts = [
        'tolerancia_precorte_pct' => 'decimal:4',
        'tolerancia_corte_abs' => 'decimal:2',
    ];
}