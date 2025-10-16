<?php

namespace App\Models\Core;

use Illuminate\Database\Eloquent\Model;

class PreCorte extends Model
{
    protected $table = 'selemti.precorte';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'sesion_id', 'declarado_efectivo', 'declarado_otros', 'estatus', 'creado_en', 
        'creado_por', 'ip_cliente', 'notas'
    ];

    protected $casts = [
        'declarado_efectivo' => 'decimal:2',
        'declarado_otros' => 'decimal:2',
        'creado_en' => 'datetime',
        'ip_cliente' => 'string',
    ];

    public function sesion()
    {
        return $this->belongsTo(SesionCaja::class, 'sesion_id');
    }
}