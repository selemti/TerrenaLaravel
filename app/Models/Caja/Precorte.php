<?php

namespace App\Models\Caja;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Precorte extends Model
{
    use HasFactory;

    protected $connection = 'pgsql';

    protected $table = 'selemti.precorte';

    public $timestamps = true;

    protected $fillable = [
        'id', 'sesion_id', 'estatus',
        'declarado_efectivo', 'declarado_otros',
        'efectivo_declarado', 'tarjetas_declaradas',
        'denominaciones', 'notas',
        'creado_en', 'creado_por', 'ip_cliente',
        'enviado_en', 'aprobado_en',
    ];

    protected $casts = [
        'denominaciones' => 'array',
        'declarado_efectivo' => 'decimal:2',
        'declarado_otros' => 'decimal:2',
        'efectivo_declarado' => 'decimal:2',
        'creado_en' => 'datetime',
        'enviado_en' => 'datetime',
        'aprobado_en' => 'datetime',
        'ip_cliente' => 'string',
    ];

    public function sesion()
    {
        return $this->belongsTo(SesionCajon::class, 'sesion_id', 'id');
    }
}
