<?php

namespace App\Models\Core;

use Illuminate\Database\Eloquent\Model;

class PostCorte extends Model
{
    protected $table = 'postcorte';
    protected $primaryKey = 'id';
    public $timestamps = false; // No usa updated_at

    protected $fillable = [
        'sesion_id', 'sistema_efectivo_esperado', 'declarado_efectivo', 'diferencia_efectivo', 
        'veredicto_efectivo', 'sistema_tarjetas', 'declarado_tarjetas', 'diferencia_tarjetas', 
        'veredicto_tarjetas', 'creado_en', 'creado_por', 'notas', 'sistema_transferencias', 
        'declarado_transferencias', 'diferencia_transferencias', 'veredicto_transferencias', 
        'validado', 'validado_por', 'validado_en'
    ];

    protected $casts = [
        'sistema_efectivo_esperado' => 'decimal:2',
        'declarado_efectivo' => 'decimal:2',
        'diferencia_efectivo' => 'decimal:2',
        'validado' => 'boolean',
        'creado_en' => 'datetime',
        'validado_en' => 'datetime',
    ];

    public function sesion()
    {
        return $this->belongsTo(SesionCaja::class, 'sesion_id');
    }
}