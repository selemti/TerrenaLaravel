<?php

namespace App\Models\Caja;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Postcorte extends Model
{
    use HasFactory;

    protected $table = 'postcorte';
    protected $schema = 'selemti';
    public $timestamps = true;

    protected $fillable = [
        'id', 'sesion_id', 'sistema_efectivo', 'declarado_efectivo', 'diferencia_efectivo',
        'veredicto_efectivo', 'notas', 'validado', 'validado_por', 'validado_en',
        // ... otros campos de totalesDeclarados
    ];

    protected $casts = [
        'sistema_efectivo' => 'decimal:2',
        'diferencia_efectivo' => 'decimal:2',
        'validado' => 'boolean',
        'validado_en' => 'datetime',
    ];

    public function sesion()
    {
        return $this->belongsTo(SesionCajon::class, 'sesion_id', 'id');
    }
}