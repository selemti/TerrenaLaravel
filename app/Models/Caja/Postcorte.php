<?php

namespace App\Models\Caja;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Postcorte extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';

    protected $table = 'selemti.postcorte';

    public $timestamps = true;

    protected $fillable = [
        'sesion_id',
        'sistema_efectivo_esperado', 'declarado_efectivo', 'diferencia_efectivo', 'veredicto_efectivo',
        'sistema_tarjetas', 'declarado_tarjetas', 'diferencia_tarjetas', 'veredicto_tarjetas',
        'sistema_transferencias', 'declarado_transferencias', 'diferencia_transferencias', 'veredicto_transferencias',
        'creado_en', 'creado_por',
        'notas', 'validado', 'validado_por', 'validado_en',
        'requiere_aprobacion', 'aprobado_por', 'aprobado_en',
        'motivo_irregular', 'rechazado', 'motivo_rechazo',
    ];

    protected $casts = [
        'sistema_efectivo_esperado' => 'decimal:2',
        'declarado_efectivo' => 'decimal:2',
        'diferencia_efectivo' => 'decimal:2',
        'sistema_tarjetas' => 'decimal:2',
        'declarado_tarjetas' => 'decimal:2',
        'diferencia_tarjetas' => 'decimal:2',
        'sistema_transferencias' => 'decimal:2',
        'declarado_transferencias' => 'decimal:2',
        'diferencia_transferencias' => 'decimal:2',
        'validado' => 'boolean',
        'requiere_aprobacion' => 'boolean',
        'rechazado' => 'boolean',
        'creado_en' => 'datetime',
        'validado_en' => 'datetime',
        'aprobado_en' => 'datetime',
    ];

    public function sesion()
    {
        return $this->belongsTo(SesionCajon::class, 'sesion_id', 'id');
    }
}
